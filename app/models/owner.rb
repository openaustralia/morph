# frozen_string_literal: true

# A user or organization that a scraper belongs to
class Owner < ApplicationRecord
  extend FriendlyId
  friendly_id :nickname

  # Using smaller batch_size than the default for the time being because
  # reindexing causes elasticsearch on the local VM to run out of memory
  searchkick batch_size: 100 # defaults to 1000

  has_many :scrapers, inverse_of: :owner, dependent: :restrict_with_exception
  has_many :runs, dependent: :restrict_with_exception
  before_create :set_api_key
  has_many :watches, class_name: "Alert", foreign_key: :watch_id, dependent: :destroy
  has_many :watchers, through: :watches, source: :user

  serialize :feature_switches

  # Supporters that are on a particular plan
  scope :supporters, ->(plan) { where(stripe_plan_id: plan.stripe_plan_id) }

  scope :all_supporters, -> { where.not(stripe_plan_id: "") }

  # Specify the data searchkick should index
  def search_data
    as_json only: %i[name nickname company]
  end

  def get_feature_switch_value(key, default)
    if feature_switches.respond_to?(:key?) && feature_switches.key?(key)
      feature_switches[key] == "1"
    else
      default
    end
  end

  def set_feature_switch_value(key, value)
    s = feature_switches || {}
    s[key] = value
    self.feature_switches = s
  end

  def name
    # If nickname and name are identical return nil
    return nil if self[:name] == nickname

    self[:name]
  end

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

  def wall_time
    runs.sum(:wall_time)
  end

  def utime
    scrapers.joins(:metrics).sum(:utime)
  end

  def stime
    scrapers.joins(:metrics).sum(:stime)
  end

  def cpu_time
    utime + stime
  end

  def repo_size
    scrapers.sum(:repo_size)
  end

  def sqlite_db_size
    scrapers.sum(:sqlite_db_size)
  end

  def total_disk_usage
    repo_size + sqlite_db_size
  end

  def set_api_key
    self.api_key =
      Digest::MD5.base64digest(id.to_s + rand.to_s + Time.zone.now.to_s)[0...20]
  end

  def github_url
    "https://github.com/#{nickname}"
  end

  # Organizations and users store their gravatar in different ways
  # TODO: Fix this
  def gravatar_url(size = 440)
    url = self[:gravatar_url]
    return if url.nil?

    u = URI.parse(url)
    queries = (u.query || "").split("&")
    queries << "s=#{size}"
    u.query = queries.join("&")
    u.to_s
  end

  def repo_root
    "db/scrapers/repos/#{to_param}"
  end

  def data_root
    "db/scrapers/data/#{to_param}"
  end

  def ability
    @ability ||= Ability.new(self)
  end

  def supporter?
    stripe_plan_id.present?
  end

  def plan
    Plan.new(stripe_plan_id)
  end
end
