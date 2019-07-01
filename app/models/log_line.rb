# frozen_string_literal: true

# Output (stdout & stderr) from a scraper
class LogLine < ActiveRecord::Base
  belongs_to :run
end
