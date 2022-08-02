# frozen_string_literal: true

require "spec_helper"

describe Scraper do
  let(:user) { create(:user) }

  context "with a scraper with a couple of runs" do
    let(:time1) { 2.minutes.ago }
    let(:time2) { 1.minute.ago }
    let(:scraper) do
      VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
        create(:scraper)
      end
    end
    let!(:run1) do
      run = scraper.runs.create!(owner: user, finished_at: time1)
      Metric.create(utime: 10.2, stime: 2.4, run_id: run.id)
      run
    end
    let!(:run2) do
      run = scraper.runs.create!(owner: user, finished_at: time2)
      Metric.create(utime: 1.3, stime: 3.5, run_id: run.id)
      run
    end

    it "#utime" do
      expect(scraper.utime).to be_within(0.00001).of(11.5)
    end

    it "#stime" do
      expect(scraper.stime).to be_within(0.00001).of(5.9)
    end

    it "#cpu_time" do
      expect(scraper.cpu_time).to be_within(0.00001).of(17.4)
    end

    describe "#scraperwiki_shortname" do
      it do
        scraper.scraperwiki_url = "https://classic.scraperwiki.com/scrapers/australian_rainfall/"
        expect(scraper.scraperwiki_shortname).to eq "australian_rainfall"
      end
    end

    describe "#scraperwiki_url" do
      it do
        scraper.scraperwiki_shortname = "australian_rainfall"
        expect(scraper.scraperwiki_url).to eq "https://classic.scraperwiki.com/scrapers/australian_rainfall/"
      end

      it do
        scraper.scraperwiki_shortname = nil
        expect(scraper.scraperwiki_url).to be_nil
      end

      it do
        scraper.scraperwiki_shortname = ""
        expect(scraper.scraperwiki_url).to be_nil
      end
    end

    describe "#latest_successful_run_time" do
      context "when the first run is successful" do
        before do
          run1.update(status_code: 0)
          run2.update(status_code: 255)
        end

        it { expect(scraper.latest_successful_run_time.to_s).to eq time1.to_s }
      end

      context "when the second run is successful" do
        before do
          run1.update(status_code: 255)
          run2.update(status_code: 0)
        end

        it { expect(scraper.latest_successful_run_time.to_s).to eq time2.to_s }
      end

      context "when neither are successful" do
        before do
          run1.update(status_code: 255)
          run2.update(status_code: 255)
        end

        it { expect(scraper.latest_successful_run_time).to be_nil }
      end

      context "when both are successful" do
        before do
          run1.update(status_code: 0)
          run2.update(status_code: 0)
        end

        it { expect(scraper.latest_successful_run_time.to_s).to eq time2.to_s }
      end
    end
  end

  describe "unique names" do
    it "does not allow duplicate scraper names for a user" do
      user = create :user
      VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
        create :scraper, name: "my_scraper", owner: user
        expect(build(:scraper, name: "my_scraper", owner: user)).not_to be_valid
      end
    end

    it "allows the same scraper name for a different user" do
      user1 = create :user
      user2 = create :user
      VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
        create :scraper, name: "my_scraper", owner: user1
        expect(build(:scraper, name: "my_scraper", owner: user2)).to be_valid
      end
    end
  end

  describe "ScraperWiki validations" do
    it "is invalid if the scraperwiki shortname is not set" do
      VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
        expect(build(:scraper, scraperwiki_url: "foobar")).not_to be_valid
      end
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
        result = double
        expect(last_run).to receive(:domains).and_return(result)
        expect(scraper.scraped_domains).to eq result
      end
    end
  end

  context "with a scraper with some downloads" do
    let(:scraper) { described_class.create!(name: "scraper", owner: owner1) }
    let(:owner1) { Owner.create }
    let(:owner2) { Owner.create }

    before do
      scraper.api_queries.create(owner: owner1, created_at: Date.new(2015, 5, 8))
      scraper.api_queries.create(owner: owner2, created_at: Date.new(2015, 5, 8))
      scraper.api_queries.create(owner: owner2, created_at: Date.new(2015, 5, 8))
    end

    describe "#download_count_by_owner" do
      it do
        expect(scraper.download_count_by_owner).to eq [[owner2, 2], [owner1, 1]]
      end
    end

    describe "#download_count" do
      it do
        expect(scraper.download_count).to eq 3
      end
    end
  end

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

  describe "#deliver_webhooks" do
    let(:run) { Run.create!(owner: user) }

    context "with no webhooks" do
      it "doesn't queue any background jobs" do
        VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
          scraper = create(:scraper)
          expect do
            scraper.deliver_webhooks(run)
          end.not_to change(DeliverWebhookWorker.jobs, :size)
        end
      end
    end

    context "with webhooks" do
      let!(:scraper) do
        VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
          scraper = create(:scraper)
          3.times { |n| scraper.webhooks.create!(url: "https://example.org/#{n}") }
          scraper
        end
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
end
