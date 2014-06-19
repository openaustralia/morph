require 'new_relic/agent/method_tracer'

class Owner < ActiveRecord::Base
  extend FriendlyId
  friendly_id :nickname

  has_many :scrapers, inverse_of: :owner
  has_many :runs
  before_create :set_api_key
  has_many :watches, class_name: "Alert", foreign_key: :watch_id
  has_many :watchers, through: :watches, source: :user

  serialize :feature_switches

  # TODO Fix up type conversion
  def buildpacks
    feature_switches[:buildpacks] == "1" if feature_switches.respond_to?(:has_key?)
  end

  def buildpacks=(value)
    s = feature_switches || {}
    s[:buildpacks] = value
    self.feature_switches = s
  end

  def name
    # If nickname and name are identical return nil
    if read_attribute(:name) != nickname
      read_attribute(:name)
    end
  end

  def blog
    b = read_attribute(:blog)
    if b.blank?
      nil
    elsif b =~ /https?:\/\//
      b
    else
      "http://" + b
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

  add_method_tracer :wall_time, 'Custom/Owner/wall_time'
  add_method_tracer :utime, 'Custom/Owner/utime'
  add_method_tracer :stime, 'Custom/Owner/stime'
  add_method_tracer :cpu_time, 'Custom/Owner/cpu_time'
  add_method_tracer :total_disk_usage, 'Custom/Owner/total_disk_usage'

  def set_api_key
    self.api_key = Digest::MD5.base64digest(id.to_s + rand.to_s + Time.now.to_s)[0...20]
  end

  def github_url
    "https://github.com/#{nickname}"
  end

  # Organizations and users store their gravatar in different ways
  # TODO Fix this
  def gravatar_url(size = 440)
    url = read_attribute(:gravatar_url)
    if url
      if url =~ /^https:\/\/(identicons.github.com|avatars.githubusercontent.com)/
        # Can't seem to change the size for the github images
        url
      else
        url + "&s=#{size}"
      end
    end
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
end
