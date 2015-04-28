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

    it "should sort them so the ones broken for the longest time come first" do
      scraper2 = FactoryGirl.create(:scraper)
      user.toggle_watch(scraper2)

      # Scraper1 ran successfully once but not most recently
      old_successful_run = FactoryGirl.create(:run, scraper: scraper, queued_at: 2.days.ago, finished_at: 2.days.ago, status_code: 0)
      errored_run = FactoryGirl.create(:run, scraper: scraper, queued_at: 1.day.ago, finished_at: 1.day.ago, status_code: 1)
      # Scraper2 never ran successfully
      scraper2_errored_run = FactoryGirl.create(:run, scraper: scraper2, finished_at: 1.week.ago, status_code: 1)

      expect(user.broken_runs).to eq [scraper2_errored_run, errored_run]
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
