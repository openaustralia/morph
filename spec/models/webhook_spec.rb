# frozen_string_literal: true

require "spec_helper"

RSpec.describe Webhook, type: :model do
  describe "#url" do
    it "requires a url" do
      webhook = Webhook.new
      expect(webhook).not_to be_valid
      expect(webhook.errors.keys).to eq([:url])
    end

    it "does not allow duplicate webhooks for the same scraper" do
      owner = Owner.create!
      scraper = Scraper.create!(name: "scraper", owner: owner)
      Webhook.create!(scraper: scraper, url: "https://example.org")

      expect(Webhook.new(scraper: scraper, url: "https://example.org")).not_to be_valid
    end

    it "is not an invalid URL" do
      w = Webhook.new(url: "foo bar")

      expect(w).not_to be_valid
      expect(w.errors[:url]).to include "is not a valid URL"
    end
  end

  describe "#last_delivery" do
    it "returns the most recently sent delivery" do
      webhook = Webhook.create!(url: "https://example.org")
      delivery1 = webhook.deliveries.create!(created_at: 3.hours.ago, sent_at: 1.hour.ago)
      webhook.deliveries.create!(created_at: 2.hours.ago, sent_at: 2.hours.ago)
      expect(webhook.last_delivery).to eq(delivery1)
    end
  end
end
