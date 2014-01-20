class Owner < ActiveRecord::Base
  extend FriendlyId
  friendly_id :nickname, use: :finders

  has_many :scrapers

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
end
