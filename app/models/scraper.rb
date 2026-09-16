# typed: strict
# frozen_string_literal: true

# A scraper is a script that runs that gets data from the web
#
# == Schema Information
#
# Table name: scrapers
#
#  id                         :integer          not null, primary key
#  auto_run                   :boolean          default(FALSE), not null
#  description                :string(255)
#  forge_key                  :string(255)      default("github"), not null
#  full_name                  :string(255)      not null
#  git_url                    :string(255)
#  memory_mb                  :integer
#  name                       :string(255)      default(""), not null
#  original_language_key      :string(255)
#  private                    :boolean          default(FALSE), not null
#  repo_size                  :integer          default(0), not null
#  repo_url                   :string(255)
#  scraperwiki_url            :string(255)
#  sqlite_db_size             :bigint           default(0), not null
#  created_at                 :datetime
#  updated_at                 :datetime
#  create_scraper_progress_id :integer
#  forge_repo_id              :integer
#  forked_by_id               :integer
#  owner_id                   :integer          not null
#
# Indexes
#
#  fk_rails_44c3dd8af8                  (create_scraper_progress_id)
#  index_scrapers_on_full_name          (full_name) UNIQUE
#  index_scrapers_on_owner_id           (owner_id)
#  index_scrapers_on_owner_id_and_name  (owner_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (create_scraper_progress_id => create_scraper_progresses.id)
#
class Scraper < ApplicationRecord
  extend T::Sig

  include RenderSync::Actions
  include Scraper::OnForge
  # Using smaller batch_size than the default for the time being because
  # reindexing causes elasticsearch on the local VM to run out of memory
  # defaults to 1000
  searchkick word_end: [:scraped_domain_names], word_middle: [:full_name],
             batch_size: 100

  belongs_to :owner, inverse_of: :scrapers
  belongs_to :forked_by, class_name: "User", optional: true

  has_many :runs, inverse_of: :scraper, dependent: :destroy
  has_one :last_run, -> { order "queued_at DESC" }, class_name: "Run", dependent: :destroy, inverse_of: :scraper
  has_many :metrics, through: :runs
  has_many :contributions, dependent: :delete_all
  has_many :contributors, through: :contributions, source: :user
  has_many :collaborations, dependent: :delete_all
  has_many :collaborators, through: :collaborations, source: :owner
  has_many :watches, class_name: "Alert", foreign_key: :watch_id, dependent: :delete_all, inverse_of: :watch
  has_many :watchers, through: :watches, source: :user
  belongs_to :create_scraper_progress, dependent: :delete, optional: true
  has_many :variables, dependent: :delete_all
  accepts_nested_attributes_for :variables, allow_destroy: true
  has_many :webhooks, dependent: :destroy
  accepts_nested_attributes_for :webhooks, allow_destroy: true
  validates_associated :variables
  delegate :sqlite_total_rows, to: :database

  has_many :api_queries, dependent: :delete_all

  validates :name, presence: true, format: { with: /\A[a-zA-Z0-9_-]+\z/ }
  validates :name, uniqueness: { scope: :owner, case_sensitive: false }

  extend FriendlyId
  friendly_id :full_name

  delegate :finished_recently?, :finished_at, :finished_successfully?,
           :finished_with_errors?, :queued?, :running?, :stop!,
           to: :last_run, allow_nil: true

  sig { returns(T::Array[Scraper]) }
  def self.running
    Run.running.map(&:scraper).compact
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def search_data
    {
      full_name: full_name,
      description: description,
      scraped_domain_names: scraped_domain_names,
      data?: data?
    }
  end

  sig { returns(T::Boolean) }
  def data?
    sqlite_total_rows.positive?
  end

  sig { returns(T::Array[String]) }
  def scraped_domain_names
    scraped_domains.map(&:name)
  end

  sig { returns(T.any(ActiveRecord::Associations::CollectionProxy, [])) }
  def scraped_domains
    last_run&.domains || []
  end

  sig { returns(T::Array[User]) }
  def all_watchers
    owner_watchers = owner&.watchers || []
    (watchers + owner_watchers).uniq
  end

  # Also orders the owners by number of downloads
  sig { returns(T::Array[[Owner, Integer]]) }
  def download_count_by_owner
    # TODO: Simplify this by using an association on api_query
    count_by_owner_id = api_queries
                        .group(:owner_id)
                        .order("count_all desc")
                        .count
    count_by_owner_id.map do |id, count|
      [Owner.find(id), count]
    end
  end

  sig { returns(Integer) }
  def download_count
    api_queries.count
  end

  sig { returns(T.nilable(Morph::Language)) }
  def original_language
    o = original_language_key
    Morph::Language.new(o.to_sym) if o
  end

  sig { returns(ActiveRecord::AssociationRelation) }
  def successful_runs
    runs.order(finished_at: :desc).finished_successfully
  end

  sig { returns(T.nilable(Time)) }
  def latest_successful_run_time
    latest_successful_run = successful_runs.first
    latest_successful_run&.finished_at
  end

  sig { returns(ActiveRecord::AssociationRelation) }
  def finished_runs
    runs.where.not(finished_at: nil).order(finished_at: :desc)
  end

  # For successful runs calculates the average wall clock time that this scraper
  # takes. Handy for the user to know how long it should expect to run for
  # Returns nil if not able to calculate this
  # TODO: Refactor this using scopes
  sig { returns(T.nilable(Float)) }
  def average_successful_wall_time
    return if successful_runs.count.zero?

    successful_runs.sum(:wall_time) / successful_runs.count
  end

  sig { returns(Float) }
  def total_wall_time
    runs.to_a.sum(&:wall_time).to_f
  end

  sig { returns(Float) }
  def utime
    metrics.sum(:utime)
  end

  sig { returns(Float) }
  def stime
    metrics.sum(:stime)
  end

  sig { returns(Float) }
  def cpu_time
    utime + stime
  end

  sig { void }
  def update_sqlite_db_size
    update(sqlite_db_size: database.sqlite_db_size)
  end

  sig { returns(Integer) }
  def total_disk_usage
    repo_size + sqlite_db_size
  end

  # Let's say a scraper requires attention if it's set to run automatically and
  # the last run failed
  # TODO: This is now inconsistent with the way this is handled elsewhere
  sig { returns(T::Boolean) }
  def requires_attention?
    l = last_run
    auto_run && !l.nil? && l.finished_with_errors?
  end

  sig { void }
  def destroy_repo_and_data
    FileUtils.rm_rf repo_path
    FileUtils.rm_rf data_path
  end

  sig { returns(String) }
  def repo_path
    "#{owner&.repo_root}/#{name}"
  end

  sig { returns(String) }
  def data_path
    "#{owner&.data_root}/#{name}"
  end

  sig { returns(T.nilable(String)) }
  def readme
    f = Dir.glob(File.join(repo_path, "README*")).first
    # rubocop:disable Rails/OutputSafety
    GitHub::Markup.render(f, File.read(f)).html_safe if f
    # rubocop:enable Rails/OutputSafety
  end

  sig { returns(String) }
  def readme_filename
    Pathname.new(Dir.glob(File.join(repo_path, "README*")).first).basename.to_s
  end

  sig { returns(T::Boolean) }
  def runnable?
    l = last_run
    l.nil? || l.finished?
  end

  sig { void }
  def queue!
    # Guard against more than one of a particular scraper running at the
    # same time
    return unless runnable?

    run = runs.create(queued_at: Time.zone.now, auto: false, owner_id: owner_id)
    RunWorker.perform_async(T.must(run.id))
  end

  sig { returns(T.nilable(Morph::Language)) }
  def language
    Morph::Language.language(repo_path)
  end

  sig { returns(T.nilable(String)) }
  def main_scraper_filename
    language&.scraper_filename
  end

  sig { returns(Morph::Database) }
  def database
    Morph::Database.new(data_path)
  end

  sig { returns(T.nilable(String)) }
  def platform
    platform_file = "#{repo_path}/platform"
    platform = File.read(platform_file).chomp if File.exist?(platform_file)
    # TODO: We should remove support for early_release at some stage
    platform = "heroku-24" if platform == "early_release"
    platform
  end

  sig { params(run: Run).void }
  def deliver_webhooks(run)
    webhooks.each do |webhook|
      webhook_delivery = webhook.deliveries.create!(run: run)
      DeliverWebhookWorker.perform_async(webhook_delivery.id)
    end
  end

  # Trims log lines older than DISCARD_AFTER_DAYS, keeping at least KEEP_AT_LEAST_COUNT_PER_STATUS log lines for
  # both successful and erroneous runs
  # Returns the number of log_lines deleted
  sig { returns(Integer) }
  def trim_log_lines
    cutoff_date = LogLine::DISCARD_AFTER_DAYS.days.ago

    # Get IDs directly using pluck instead of building subqueries with LIMIT
    keep_ids = []

    # Keep the most recent N successful runs
    keep_ids += runs.where(status_code: 0)
                    .order(id: :desc)
                    .limit(LogLine::KEEP_AT_LEAST_COUNT_PER_STATUS)
                    .pluck(:id)

    # Keep the most recent N unsuccessful runs
    keep_ids += runs.where.not(status_code: 0)
                    .order(id: :desc)
                    .limit(LogLine::KEEP_AT_LEAST_COUNT_PER_STATUS)
                    .pluck(:id)

    # Keep runs created after the cutoff date
    keep_ids += runs.where("created_at > ?", cutoff_date)
                    .pluck(:id)

    # Remove duplicates
    keep_ids.uniq!

    total_deleted = 0
    LogLine.where(run_id: runs.where.not(id: keep_ids).select(:id))
           .in_batches(of: 200) do |batch|
      deleted = batch.delete_all
      total_deleted += deleted
      sleep(0.05) if deleted.positive? # Brief pause between chunks to be nice to the database
    end

    total_deleted
  end
end
