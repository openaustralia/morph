# typed: false
# frozen_string_literal: true

require "spec_helper"

describe DeliverWebhookWorker, :vcr do
  let(:scraper) do
    VCR.use_cassette("scraper_validations") do
      create(:scraper)
    end
  end
  let(:run) { create(:run) }

  it "works" do
    VCR.use_cassette("webhook_delivery") do
      webhook = Webhook.create!(scraper: scraper, url: "http://requestb.in/x3pcr8x3")
      webhook_delivery = webhook.deliveries.create!(run: run)
      described_class.new.perform(webhook_delivery.id)
      webhook_delivery.reload
      expect(webhook_delivery.response_code).to be(200)
      expect(webhook_delivery.sent_at).to be_within(1.minute).of(DateTime.now)
    end
  end
end
