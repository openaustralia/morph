# typed: strict
# frozen_string_literal: true

# == Schema Information
#
# Table name: alerts
#
#  id         :integer          not null, primary key
#  watch_type :string(255)
#  created_at :datetime
#  updated_at :datetime
#  user_id    :integer
#  watch_id   :integer
#
# Indexes
#
#  index_alerts_on_user_id     (user_id)
#  index_alerts_on_watch_id    (watch_id)
#  index_alerts_on_watch_type  (watch_type)
#

# A user watching something - can be a scraper, a user or an org
class Alert < ApplicationRecord
  belongs_to :watch, polymorphic: true
  belongs_to :user
end
