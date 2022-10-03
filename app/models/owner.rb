# typed: strict
# frozen_string_literal: true

# A user or organization that a scraper belongs to
class Owner < ApplicationRecord
  extend T::Sig
  extend T::Helpers
  abstract!

  extend FriendlyId
  friendly_id :nickname

  # Using smaller batch_size than the default for the time being because
  # reindexing causes elasticsearch on the local VM to run out of memory
  searchkick batch_size: 100 # defaults to 1000

  has_many :scrapers, inverse_of: :owner, dependent: :restrict_with_exception
  has_many :runs, dependent: :restrict_with_exception
  before_create :set_api_key
  has_many :watches, class_name: "Alert", foreign_key: :watch_id, dependent: :destroy, inverse_of: :watch
  has_many :watchers, through: :watches, source: :user

  serialize :feature_switches

  # Supporters that are on a particular plan
  scope :supporters, ->(plan) { where(stripe_plan_id: plan.stripe_plan_id) }

  scope :all_supporters, -> { where.not(stripe_plan_id: "") }

  # Specify the data searchkick should index
  sig { returns(T::Hash[String, T.nilable(String)]) }
  def search_data
    as_json only: %i[name nickname company]
  end

  sig { abstract.returns(T::Boolean) }
  def user?; end

  sig { abstract.returns(T::Boolean) }
  def organization?; end

  sig { returns(T.nilable(String)) }
  def name
    # If nickname and name are identical return nil
    return nil if self[:name] == nickname

    self[:name]
  end

  sig { returns(T.nilable(String)) }
  def blog
    b = self[:blog]
    if b.blank?
      nil
    elsif b =~ %r{https?://}
      b
    else
      "http://#{b}"
    end
  end

  sig { returns(Float) }
  def wall_time
    runs.sum(:wall_time)
  end

  sig { returns(Float) }
  def utime
    scrapers.joins(:metrics).sum(:utime)
  end

  sig { returns(Float) }
  def stime
    scrapers.joins(:metrics).sum(:stime)
  end

  sig { returns(Float) }
  def cpu_time
    utime + stime
  end

  sig { returns(Integer) }
  def repo_size
    scrapers.sum(:repo_size)
  end

  sig { returns(Integer) }
  def sqlite_db_size
    scrapers.sum(:sqlite_db_size)
  end

  sig { returns(Integer) }
  def total_disk_usage
    repo_size + sqlite_db_size
  end

  sig { void }
  def set_api_key
    self.api_key =
      Digest::MD5.base64digest(id.to_s + rand.to_s + Time.zone.now.to_s)[0...20]
  end

  sig { returns(String) }
  def github_url
    "https://github.com/#{nickname}"
  end

  # Organizations and users store their gravatar in different ways
  # TODO: Fix this
  # TODO: Move this out of the model
  sig { params(size: Integer).returns(T.nilable(String)) }
  def gravatar_url(size = 440)
    url = self[:gravatar_url]
    return if url.nil?

    u = URI.parse(url)
    queries = (u.query || "").split("&")
    queries << "s=#{size}"
    u.query = queries.join("&")
    u.to_s
  end

  sig { returns(String) }
  def repo_root
    "db/scrapers/repos/#{to_param}"
  end

  sig { returns(String) }
  def data_root
    "db/scrapers/data/#{to_param}"
  end

  sig { returns(T::Boolean) }
  def supporter?
    stripe_plan_id.present?
  end

  sig { returns(T.nilable(Plan)) }
  def plan
    s = stripe_plan_id
    Plan.new(s) if s
  end

  # This returns a url to install the Morph Github app for this owner. It also suggests the repos to select based on
  # the scrapers that this owner already has
  sig { returns(String) }
  def app_install_url
    params = { suggested_target_id: uid, repository_ids: scrapers.map(&:github_id) }
    "https://github.com/apps/#{Morph::Environment.github_app_name}/installations/new/permissions?#{params.to_query}"
  end
end
