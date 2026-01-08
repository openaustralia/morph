# typed: strict
# frozen_string_literal: true

# Output (stdout & stderr) from a scraper run
#
# == Schema Information
#
# Table name: log_lines
#
#  id         :integer          not null, primary key
#  stream     :string(255)
#  text       :text(65535)
#  timestamp  :datetime
#  created_at :datetime
#  updated_at :datetime
#  run_id     :integer
#
# Indexes
#
#  index_log_lines_on_run_id     (run_id)
#  index_log_lines_on_timestamp  (timestamp)
#
# Foreign Keys
#
#  fk_rails_...  (run_id => runs.id)
#
class LogLine < ApplicationRecord
  belongs_to :run

  DISCARD_AFTER_DAYS = 30
  KEEP_AT_LEAST_COUNT_PER_STATUS = 3
end
