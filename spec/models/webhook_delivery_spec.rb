# typed: false
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
require "spec_helper"

RSpec.describe WebhookDelivery, type: :model do
  describe "#success?" do
    it "returns true if the status code is 2xx" do
      webhook_delivery = described_class.new(response_code: 200)
      expect(webhook_delivery.success?).to be true
    end
  end
end
