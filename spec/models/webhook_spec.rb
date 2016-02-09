require 'spec_helper'

RSpec.describe Webhook, type: :model do
  it "should require a url" do
    webhook = Webhook.new
    expect(webhook).to_not be_valid
    expect(webhook.errors.keys).to eq([:url])
  end

  describe "#last_delivery" do
    it "should return the most recently sent delivery" do
      webhook = Webhook.create!(url: 'https://example.org')
      delivery1 = webhook.deliveries.create!(created_at: 3.hours.ago, sent_at: 1.hour.ago)
      delivery2 = webhook.deliveries.create!(created_at: 2.hours.ago, sent_at: 2.hours.ago)
      expect(webhook.last_delivery).to eq(delivery1)
    end
  end
end
