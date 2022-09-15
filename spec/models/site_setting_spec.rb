# typed: false
# frozen_string_literal: true

require "spec_helper"

describe SiteSetting do
  describe ".read_only_mode" do
    it "is false by default" do
      expect(described_class.read_only_mode).to be false
    end

    it "persists a setting" do
      described_class.read_only_mode = true
      expect(described_class.read_only_mode).to be true
    end
  end

  describe ".toggle_read_only_mode!" do
    it "toggles false to true" do
      described_class.read_only_mode = false
      described_class.toggle_read_only_mode!
      expect(described_class.read_only_mode).to be true
    end

    it "toggles true to false" do
      described_class.read_only_mode = true
      described_class.toggle_read_only_mode!
      expect(described_class.read_only_mode).to be false
    end
  end

  describe ".maximum_concurrent_scrapers" do
    it "is 20 by default" do
      expect(described_class.maximum_concurrent_scrapers).to eq 20
    end

    it "persists a setting" do
      described_class.maximum_concurrent_scrapers = 10
      expect(described_class.maximum_concurrent_scrapers).to eq 10
    end

    it "updates the sidekiq value at the same time" do
      allow(described_class).to receive(:update_maximum_concurrent_scrapers!)
      described_class.maximum_concurrent_scrapers = 10
      expect(described_class).to have_received(:update_maximum_concurrent_scrapers!)
    end
  end

  describe ".update_maximum_concurrent_scrapers!" do
    it "sets the sidekiq value" do
      allow(Sidekiq::Queue["scraper"]).to receive(:limit=)
      described_class.maximum_concurrent_scrapers = 10
      described_class.update_maximum_concurrent_scrapers!
      expect(Sidekiq::Queue["scraper"]).to have_received(:limit=).twice.with(10)
    end
  end
end
