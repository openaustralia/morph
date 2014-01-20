class Owner < ActiveRecord::Base
  extend FriendlyId
  friendly_id :nickname, use: :finders

  has_many :scrapers

  def github_url
    "https://github.com/#{nickname}"
  end
end
