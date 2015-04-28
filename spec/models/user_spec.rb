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

  describe "#broken_runs" do
    let(:user) { FactoryGirl.create(:user) }
    let(:scraper) { FactoryGirl.create(:scraper) }
    before { user.toggle_watch(scraper) }

    it "watching a scraper with no runs should be empty" do
      expect(user.broken_runs).to be_empty
    end

    it "watching a broken scraper should contain the run" do
      run = FactoryGirl.create(:run, scraper: scraper, finished_at: 1.week.ago, status_code: 1)
      expect(user.broken_runs).to eq [run]
    end

    it "watching a working scraper should not contain the run" do
      run = FactoryGirl.create(:run, scraper: scraper, finished_at: 1.week.ago, status_code: 0)
      expect(user.broken_runs).to eq []
    end
  end

  describe "#successful_runs" do
    let(:user) { FactoryGirl.create(:user) }
    let(:scraper) { FactoryGirl.create(:scraper) }
    before { user.toggle_watch(scraper) }

    it "watching a scraper with no runs should be empty" do
      expect(user.successful_runs).to be_empty
    end

    it "watching a broken scraper should not contain the run" do
      run = FactoryGirl.create(:run, scraper: scraper, finished_at: 1.week.ago, status_code: 1)
      expect(user.successful_runs).to eq []
    end

    it "watching a working scraper should contain the run" do
      run = FactoryGirl.create(:run, scraper: scraper, finished_at: 1.week.ago, status_code: 0)
      expect(user.successful_runs).to eq [run]
    end
  end
end
