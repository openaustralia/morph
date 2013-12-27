class Run < ActiveRecord::Base
  belongs_to :scraper
  has_many :log_lines
end
