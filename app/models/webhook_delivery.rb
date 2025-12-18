# typed: strict
# frozen_string_literal: true

# == Schema Information
#
# Table name: webhook_deliveries
#
#  id            :integer          not null, primary key
#  response_code :integer
#  sent_at       :datetime
#  created_at    :datetime
#  updated_at    :datetime
#  run_id        :integer
#  webhook_id    :integer
#
# Indexes
#
#  index_webhook_deliveries_on_run_id      (run_id)
#  index_webhook_deliveries_on_webhook_id  (webhook_id)
#
# Foreign Keys
#
#  fk_rails_...  (run_id => runs.id)
#  fk_rails_...  (webhook_id => webhooks.id)
#
class WebhookDelivery < ApplicationRecord
  extend T::Sig
  SUCCESSFUL_STATUSES = T.let((200..299), T::Range[Integer])

  belongs_to :webhook
  belongs_to :run

  sig { returns(T::Boolean) }
  def success?
    SUCCESSFUL_STATUSES.include?(response_code)
  end
end
