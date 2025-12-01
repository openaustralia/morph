# typed: strict
# frozen_string_literal: true

# Output (stdout & stderr) from a scraper run
class LogLine < ApplicationRecord
  belongs_to :run

  DISCARD_AFTER_DAYS = 30
  KEEP_AT_LEAST_COUNT_PER_STATUS = 5
end
