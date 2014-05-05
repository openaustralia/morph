class CreateScraperProgress < ActiveRecord::Base
  has_one :scraper, dependent: :nullify
end
