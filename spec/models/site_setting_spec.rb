# frozen_string_literal: true

require "spec_helper"

describe SiteSetting do
  describe ".read_only_mode" do
    it "should be false by default" do
      expect(SiteSetting.read_only_mode).to eq false
    end

    it "should persist a setting" do
      SiteSetting.read_only_mode = true
      expect(SiteSetting.read_only_mode).to eq true
    end
  end

  describe ".toggle_read_only_mode!" do
    it "should toggle false to true" do
      SiteSetting.read_only_mode = false
      SiteSetting.toggle_read_only_mode!
      expect(SiteSetting.read_only_mode).to eq true
    end

    it "should toggle true to false" do
      SiteSetting.read_only_mode = true
      SiteSetting.toggle_read_only_mode!
      expect(SiteSetting.read_only_mode).to eq false
    end
  end

  describe ".maximum_concurrent_scrapers" do
    it "should be 20 by default" do
      expect(SiteSetting.maximum_concurrent_scrapers).to eq 20
    end

    it "should persist a setting" do
      SiteSetting.maximum_concurrent_scrapers = 10
      expect(SiteSetting.maximum_concurrent_scrapers).to eq 10
    end

    it "should update the sidekiq value at the same time" do
      expect(SiteSetting).to receive(:update_sidekiq_maximum_concurrent_scrapers!)
      SiteSetting.maximum_concurrent_scrapers = 10
    end
  end

  describe ".update_sidekiq_maximum_concurrent_scrapers!" do
    it "should set the sidekiq value" do
      SiteSetting.maximum_concurrent_scrapers = 10

      expect(Sidekiq::Queue["scraper"]).to receive(:limit=).with(10)
      SiteSetting.update_sidekiq_maximum_concurrent_scrapers!
    end
  end
end
