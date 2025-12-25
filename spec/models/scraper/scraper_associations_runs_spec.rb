# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Scraper do
  let(:user) { create(:user) }

  # ============================================================================
  # ASSOCIATIONS & DELEGATIONS
  # ============================================================================

  describe "#scraped_domain_names" do
    let(:scraper) { create(:scraper) }
    # Domain is a dynamic object from connection_logs, not an internal model
    # rubocop:disable RSpec/VerifiedDoubles
    let(:domain1) { double("Domain", name: "example.com") }
    let(:domain2) { double("Domain", name: "test.org") }
    # rubocop:enable RSpec/VerifiedDoubles

    it "returns array of domain names from scraped domains" do
      allow(scraper).to receive(:scraped_domains).and_return([domain1, domain2])
      expect(scraper.scraped_domain_names).to eq(["example.com", "test.org"])
    end

    it "returns empty array when no domains" do
      allow(scraper).to receive(:scraped_domains).and_return([])
      expect(scraper.scraped_domain_names).to eq([])
    end
  end

  describe "#scraped_domains" do
    let(:scraper) { described_class.new }
    let(:last_run) { mock_model(Run) }

    it "returns an empty array if there is no last run" do
      expect(scraper.scraped_domains).to eq []
    end

    context "when there is a last run" do
      before do
        allow(scraper).to receive(:last_run).and_return(last_run)
      end

      it "defers to the last run" do
        # Need to use double for dynamic result object
        result = double
        allow(last_run).to receive(:domains).and_return(result)
        expect(scraper.scraped_domains).to eq result
      end
    end
  end

  describe "#all_watchers" do
    let(:scraper) { create(:scraper) }
    let(:watcher1) { instance_double(User) }
    let(:watcher2) { instance_double(User) }
    let(:owner_watcher) { instance_double(User) }

    it "combines watchers from scraper and owner" do
      allow(scraper).to receive(:watchers).and_return([watcher1, watcher2])
      allow(scraper.owner).to receive(:watchers).and_return([owner_watcher])

      all = scraper.all_watchers
      expect(all).to include(watcher1, watcher2, owner_watcher)
      expect(all.size).to eq(3)
    end

    it "deduplicates watchers" do
      shared_watcher = instance_double(User)
      allow(scraper).to receive(:watchers).and_return([shared_watcher])
      allow(scraper.owner).to receive(:watchers).and_return([shared_watcher])

      expect(scraper.all_watchers.size).to eq(1)
    end

    it "handles owner with no watchers" do
      allow(scraper).to receive(:watchers).and_return([watcher1])
      allow(scraper.owner).to receive(:watchers).and_return([])

      expect(scraper.all_watchers).to eq([watcher1])
    end
  end

  # ============================================================================
  # RUN MANAGEMENT & QUEUEING
  # ============================================================================

  describe "#runnable?" do
    let(:scraper) { create(:scraper) }

    it "returns true when no last run" do
      expect(scraper.runnable?).to be true
    end

    it "returns true when last run is finished" do
      scraper.runs.create!(owner: user, started_at: 1.hour.ago, finished_at: Time.zone.now)
      expect(scraper.runnable?).to be true
    end

    it "returns false when last run is still running" do
      scraper.runs.create!(owner: user, started_at: Time.zone.now)
      expect(scraper.runnable?).to be false
    end
  end

  describe "#queue!" do
    let(:scraper) { create(:scraper) }

    it "creates a new run and queues worker when runnable" do
      expect do
        scraper.queue!
      end.to change(scraper.runs, :count).by(1)

      expect(scraper.runs.last.queued_at).to be_present
      expect(scraper.runs.last.auto).to be false
    end

    it "queues RunWorker job" do
      expect do
        scraper.queue!
      end.to change(RunWorker.jobs, :size).by(1)
    end

    it "does nothing when not runnable" do
      scraper.runs.create!(owner: user, started_at: Time.zone.now)

      expect do
        scraper.queue!
      end.not_to change(scraper.runs, :count)
    end
  end

  describe "#requires_attention?" do
    let(:scraper) { create(:scraper) }

    it "returns false when auto_run is false" do
      scraper.update(auto_run: false)
      expect(scraper.requires_attention?).to be false
    end

    it "returns false when no last run" do
      scraper.update(auto_run: true)
      expect(scraper.requires_attention?).to be false
    end

    it "returns true when auto_run and last run failed" do
      scraper.update(auto_run: true)
      scraper.runs.create!(owner: user, status_code: 255, finished_at: Time.zone.now)

      expect(scraper.requires_attention?).to be true
    end

    it "returns false when auto_run but last run succeeded" do
      scraper.update(auto_run: true)
      scraper.runs.create!(owner: user, status_code: 0, finished_at: Time.zone.now)

      expect(scraper.requires_attention?).to be false
    end
  end

  # ============================================================================
  # WEBHOOKS
  # ============================================================================

  describe "#deliver_webhooks" do
    let(:run) { Run.create!(owner: user) }

    context "with no webhooks" do
      it "doesn't queue any background jobs" do
        scraper = create(:scraper)
        expect do
          scraper.deliver_webhooks(run)
        end.not_to change(DeliverWebhookWorker.jobs, :size)
      end
    end

    context "with webhooks" do
      let!(:scraper) do
        scraper = create(:scraper)
        3.times { |n| scraper.webhooks.create!(url: "https://example.org/#{n}") }
        scraper
      end

      it "queues up a background job for each webhook" do
        expect do
          scraper.deliver_webhooks(run)
        end.to change(DeliverWebhookWorker.jobs, :size).by(3)
      end

      it "creates webhook delivery records" do
        expect do
          scraper.deliver_webhooks(run)
        end.to change(WebhookDelivery, :count).by(3)
      end
    end
  end

  # ============================================================================
  # LEGACY & COMPATIBILITY TESTS
  # ============================================================================

  context "when there is a scraper" do
    let(:scraper) { described_class.new }

    context "when the scraper has no data" do
      before do
        allow(scraper).to receive(:sqlite_total_rows).and_return(0)
      end

      describe "#data?" do
        it { expect(scraper.data?).to be false }
      end
    end

    context "when the scraper has a data" do
      before do
        allow(scraper).to receive(:sqlite_total_rows).and_return(1)
      end

      describe "#data?" do
        it { expect(scraper.data?).to be true }
      end
    end

    context "when the scraper has never run" do
      describe "#finished_successfully?" do
        it { expect(scraper).not_to be_finished_successfully }
      end

      describe "#finished_with_errors?" do
        it { expect(scraper).not_to be_finished_with_errors }
      end
    end

    context "when the scraper has run but it failed" do
      let(:run) { mock_model(Run, finished_successfully?: false, finished_with_errors?: true) }

      before do
        allow(scraper).to receive(:last_run).and_return(run)
      end

      describe "#finished_successfully?" do
        it { expect(scraper).not_to be_finished_successfully }
      end

      describe "#finished_with_errors?" do
        it { expect(scraper).to be_finished_with_errors }
      end
    end

    context "when a scraper has run and it was successful" do
      let(:run) { mock_model(Run, finished_successfully?: true, finished_with_errors?: false) }

      before do
        allow(scraper).to receive(:last_run).and_return(run)
      end

      describe "#finished_successfully?" do
        it { expect(scraper).to be_finished_successfully }
      end

      describe "#finished_with_errors?" do
        it { expect(scraper).not_to be_finished_with_errors }
      end
    end
  end
end
