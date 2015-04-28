require 'spec_helper'

describe User do
  describe "#auto_runs" do
    let(:user) { FactoryGirl.create(:user) }
    let(:scraper) { FactoryGirl.create(:scraper) }
    before { user.toggle_watch(scraper) }

    it "watching a scraper with no runs should be empty" do
      expect(user.auto_runs).to be_empty
    end

    it "watching a scraper with runs should contain the run" do
      run = FactoryGirl.create(:run, scraper: scraper)
      expect(user.auto_runs).to eq [run]
    end
  end
end
