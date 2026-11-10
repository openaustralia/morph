# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::Emergency do
  describe ".find_all_runs_on_the_queue" do
    def job(klass, run_id)
      instance_double(Sidekiq::SortedEntry, klass: klass, args: [run_id])
    end

    before do
      allow(Sidekiq::RetrySet).to receive(:new).and_return([])
      allow(Sidekiq::Queue).to receive(:new).with("scraper").and_return([])
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return([])
      allow(Sidekiq::Workers).to receive(:new).and_return([])
    end

    it "includes runs queued for the scraper queue" do
      allow(Sidekiq::Queue).to receive(:new).with("scraper").and_return([job("RunWorker", 2)])
      expect(described_class.find_all_runs_on_the_queue).to eq [2]
    end

    it "includes runs waiting for a free slot, which are scheduled to try again later" do
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return([job("RunWorker", 7)])
      expect(described_class.find_all_runs_on_the_queue).to eq [7]
    end

    it "ignores scheduled jobs that are not for runs" do
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return([job("ScraperAutoRunWorker", 9)])
      expect(described_class.find_all_runs_on_the_queue).to eq []
    end
  end
end
