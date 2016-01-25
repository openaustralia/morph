class Webhook < ActiveRecord::Base
  belongs_to :scraper
end
