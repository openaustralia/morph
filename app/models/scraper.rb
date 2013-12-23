class Scraper < ActiveRecord::Base
  belongs_to :owner, class_name: User

  extend FriendlyId
  friendly_id :full_name, use: :finders
end
