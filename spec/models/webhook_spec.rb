# typed: false
# frozen_string_literal: true

# == Schema Information
#
# Table name: webhooks
#
#  id         :integer          not null, primary key
#  url        :string(255)
#  created_at :datetime
#  updated_at :datetime
#  scraper_id :integer
#
# Indexes
#
#  index_webhooks_on_scraper_id          (scraper_id)
#  index_webhooks_on_scraper_id_and_url  (scraper_id,url) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (scraper_id => scrapers.id)
#
require "spec_helper"

RSpec.describe Webhook, type: :model do
  let(:scraper) { create(:scraper) }

  describe "#url" do
    it "requires a url" do
      webhook = described_class.new(scraper: scraper)
      expect(webhook).not_to be_valid
      expect(webhook.errors.keys).to eq([:url])
    end

    it "does not allow duplicate webhooks for the same scraper" do
      owner = User.create!
      scraper = Scraper.create!(name: "scraper", owner: owner, full_name: "")
      described_class.create!(scraper: scraper, url: "https://example.org")

      expect(described_class.new(scraper: scraper, url: "https://example.org")).not_to be_valid
    end

    it "is not an invalid URL" do
      w = described_class.new(url: "foo bar")

      expect(w).not_to be_valid
      expect(w.errors[:url]).to include "is not a valid URL"
    end
  end

  describe "#last_delivery" do
    let(:run1) { create(:run) }
    let(:run2) { create(:run) }

    it "returns the most recently sent delivery" do
      webhook = described_class.create!(scraper: scraper, url: "https://example.org")
      delivery1 = webhook.deliveries.create!(run: run1, created_at: 3.hours.ago, sent_at: 1.hour.ago)
      webhook.deliveries.create!(run: run2, created_at: 2.hours.ago, sent_at: 2.hours.ago)
      expect(webhook.last_delivery).to eq(delivery1)
    end
  end
end
