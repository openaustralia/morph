# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Scraper do
  let(:user) { create(:user) }

  # ============================================================================
  # SEARCH & QUERIES
  # ============================================================================

  describe "#search_data" do
    let(:scraper) do
      create(:scraper, full_name: "owner/scraper", description: "A test scraper")
    end

    before do
      allow(scraper).to receive(:scraped_domain_names).and_return(["example.com"])
      allow(scraper).to receive(:sqlite_total_rows).and_return(10)
    end

    it "returns hash with scraper metadata for search indexing" do
      data = scraper.search_data
      expect(data[:full_name]).to eq("owner/scraper")
      expect(data[:description]).to eq("A test scraper")
      expect(data[:scraped_domain_names]).to eq(["example.com"])
      expect(data[:data?]).to be true
    end
  end

  describe "#data?" do
    let(:scraper) { create(:scraper) }

    it "returns true when scraper has data rows" do
      allow(scraper).to receive(:sqlite_total_rows).and_return(5)
      expect(scraper.data?).to be true
    end

    it "returns false when scraper has no data rows" do
      allow(scraper).to receive(:sqlite_total_rows).and_return(0)
      expect(scraper.data?).to be false
    end
  end

  context "with a scraper with some downloads" do
    let(:scraper) { described_class.create!(name: "scraper", owner: owner1, full_name: "") }
    let(:owner1) { User.create }
    let(:owner2) { User.create }

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

  # ============================================================================
  # METRICS & CALCULATIONS
  # ============================================================================

  describe "#average_successful_wall_time" do
    let(:scraper) { create(:scraper) }

    it "returns nil when no successful runs" do
      expect(scraper.average_successful_wall_time).to be_nil
    end

    it "calculates average wall time of successful runs" do
      # wall_time is calculated from finished_at - started_at, so create runs with both timestamps
      scraper.runs.create!(owner: user, status_code: 0, started_at: 10.seconds.ago, finished_at: Time.zone.now)
      scraper.runs.create!(owner: user, status_code: 0, started_at: 20.seconds.ago, finished_at: Time.zone.now)
      scraper.runs.create!(owner: user, status_code: 255, started_at: 5.seconds.ago, finished_at: Time.zone.now)

      avg = scraper.average_successful_wall_time
      expect(avg).to be_within(1.0).of(15.0)
    end
  end

  describe "#total_wall_time" do
    let(:scraper) { create(:scraper) }

    it "returns 0.0 when no runs" do
      expect(scraper.total_wall_time).to eq(0.0)
    end

    it "sums wall time across all runs" do
      # wall_time is calculated from finished_at - started_at
      scraper.runs.create!(owner: user, started_at: 10.seconds.ago, finished_at: Time.zone.now)
      scraper.runs.create!(owner: user, started_at: 5.seconds.ago, finished_at: Time.zone.now)

      total = scraper.total_wall_time
      expect(total).to be_within(1.0).of(15.0)
    end
  end

  describe "#update_sqlite_db_size" do
    let(:scraper) { create(:scraper) }
    # Morph::Database is a custom class, not an ActiveRecord model
    # rubocop:disable RSpec/VerifiedDoubles
    let(:database) { double("Morph::Database", sqlite_db_size: 1024) }
    # rubocop:enable RSpec/VerifiedDoubles

    it "updates sqlite_db_size from database" do
      allow(scraper).to receive(:database).and_return(database)

      scraper.update_sqlite_db_size
      expect(scraper.reload.sqlite_db_size).to eq(1024)
    end
  end

  describe "#total_disk_usage" do
    let(:scraper) { build(:scraper, repo_size: 500, sqlite_db_size: 1024) }

    it "returns sum of repo_size and sqlite_db_size" do
      expect(scraper.total_disk_usage).to eq(1524)
    end
  end

  context "with a scraper with a couple of runs" do
    let(:time1) { 2.minutes.ago }
    let(:time2) { 1.minute.ago }
    let(:scraper) { create(:scraper) }
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

  describe "#successful_runs and #finished_runs" do
    let(:scraper) { create(:scraper) }

    before do
      # Create successful runs with log lines
      3.times do |i|
        run = scraper.runs.create!(owner: user, status_code: 0, finished_at: (i + 10).days.ago)
        run.log_lines.create!(text: "Success log #{i}")
      end

      # Create unsuccessful runs with log lines
      3.times do |i|
        run = scraper.runs.create!(owner: user, status_code: 255, finished_at: (i + 10).days.ago)
        run.log_lines.create!(text: "Error log #{i}")
      end

      # Recent runs that shouldn't be trimmed anyway
      scraper.runs.create!(owner: user, status_code: 0, finished_at: Time.zone.now)
      scraper.runs.create!(owner: user, started_at: Time.zone.now) # not finished
    end

    describe "#successful_runs" do
      it "returns only runs with status_code 0, ordered by finished_at desc" do
        successful = scraper.successful_runs
        expect(successful.count).to eq(4)
        expect(successful.map(&:status_code)).to all(eq(0))
        expect(successful.first.finished_at).to be > successful.last.finished_at
      end

      it "keeps at least KEEP_AT_LEAST_COUNT_PER_STATUS for successful runs" do
        scraper.trim_log_lines

        successful_runs_with_logs = scraper.runs
                                           .where(status_code: 0)
                                           .joins(:log_lines)
                                           .distinct
                                           .count

        expect(successful_runs_with_logs).to be >= LogLine::KEEP_AT_LEAST_COUNT_PER_STATUS
      end

      it "keeps at least KEEP_AT_LEAST_COUNT_PER_STATUS for unsuccessful runs" do
        scraper.trim_log_lines

        failed_runs_with_logs = scraper.runs
                                       .where.not(status_code: 0)
                                       .joins(:log_lines)
                                       .distinct
                                       .count

        expect(failed_runs_with_logs).to be >= LogLine::KEEP_AT_LEAST_COUNT_PER_STATUS
      end
    end
  end
end
