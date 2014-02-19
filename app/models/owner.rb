class Owner < ActiveRecord::Base
  extend FriendlyId
  friendly_id :nickname, use: :finders

  has_many :scrapers
  has_many :runs
  before_create :set_api_key

  def wall_time
    runs.sum(&:wall_time)
  end

  def cpu_time
    scrapers.sum(&:cpu_time)
  end

  def total_disk_usage
    scrapers.sum(&:total_disk_usage)
  end

  def set_api_key
    self.api_key = Digest::MD5.base64digest(id.to_s + rand.to_s + Time.now.to_s)[0...20]
  end

  def github_url
    "https://github.com/#{nickname}"
  end

  # Organizations and users store their gravatar in different ways
  # TODO Fix this
  def gravatar_url(size = 440)
    if gravatar_id
      "https://www.gravatar.com/avatar/#{gravatar_id}?r=x&s=#{size}"
    else
      url = read_attribute(:gravatar_url)
      if url =~ /^https:\/\/identicons.github.com/
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
end
