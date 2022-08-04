# typed: false
# frozen_string_literal: true

# Output (stdout & stderr) from a scraper
class LogLine < ApplicationRecord
  belongs_to :run
end
