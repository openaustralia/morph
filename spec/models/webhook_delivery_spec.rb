# frozen_string_literal: true

require "spec_helper"

RSpec.describe WebhookDelivery, type: :model do
  context "#success?" do
    it "returns true if the status code is 2xx" do
      webhook_delivery = WebhookDelivery.new(response_code: 200)
      expect(webhook_delivery.success?).to be true
    end
  end
end
