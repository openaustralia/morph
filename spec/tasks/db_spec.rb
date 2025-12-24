# typed: false
# frozen_string_literal: true

require "spec_helper"
require "rake"

RSpec.describe "tasks" do # rubocop:disable RSpec/DescribeClass
  describe "db", type: :integration do
    before do
      Rails.application.load_tasks if Rake::Task.tasks.empty?
    end

    # Database Stats
    describe "stats" do
      it "runs without error" do
        expect { Rake::Task["db:stats"].invoke }.to output(/Table.*Count/).to_stdout
      end

      it "supports EXACT_COUNT environment variable" do
        stub_const("ENV", ENV.to_h.merge("EXACT_COUNT" => "1"))
        expect { Rake::Task["db:stats"].execute }.to output(/\(exact count\)/).to_stdout
      end
    end

    # Create a full backup of the database
    describe "backup" do
      after do
        FileUtils.rm_rf("tmp/backup")
      end

      it "creates a backup file" do
        allow($stdout).to receive(:puts) # Suppress output
        backup_file = "db/backups/backup.sql.zst"
        FileUtils.rm_f backup_file

        Rake::Task["db:backup"].execute

        expect(File.exist?(backup_file)).to be true
        expect(File.size(backup_file)).to be > 0
      end

      it "outputs help information about restoring" do
        # allow(Time).to receive(:now).and_return(Time.at(1234567890))

        expect { Rake::Task["db:backup"].execute }.to output(/To restore this backup/).to_stdout
      end
    end

    # FIXME: Test Freezes on my machine but run manually its fine, investigate further
    # Create a filtered backup of the database for use in development
    # describe "filtered_backup" do
    #   let!(:owner) { create(:user) }
    #   let!(:scraper) { create(:scraper, owner: owner) }
    #
    #   after do
    #     FileUtils.rm_rf("tmp/backup")
    #   end
    #
    #   it "creates a filtered backup with real data" do
    #     allow(Time).to receive(:now).and_return(Time.at(1234567890))
    #     allow($stdout).to receive(:puts) # Suppress output
    #
    #     expect { Rake::Task["db:filtered_backup"].execute }.not_to raise_error
    #
    #     backup_file = "tmp/backup/morph-filtered-#{Time.now.strftime('%Y-%m-%d-%H%M%S')}.sql.zst"
    #     expect(File.exist?(backup_file)).to be true
    #     expect(File.size(backup_file)).to be > 0
    #   end
    # end

    # Remove old log lines keeping some for both successful and erroneous runs
    describe "trim:log_lines" do
      context "when there is a plentiful mix of recent runs" do
        let!(:scraper) { create(:scraper) }
        let!(:more_than_keep_count) { LogLine::KEEP_AT_LEAST_COUNT_PER_STATUS + 2 }
        let!(:successful_runs) { more_than_keep_count.times.map { create(:run, scraper: scraper, status_code: 0, created_at: 1.hour.ago) } }
        let!(:failed_runs) { more_than_keep_count.times.map { create(:run, scraper: scraper, status_code: 1, created_at: 1.hour.ago) } }
        let!(:old_successful_run) { create(:run, scraper: scraper, status_code: 0, created_at: LogLine::DISCARD_AFTER_DAYS.days.ago) }
        let!(:old_failed_run) { create(:run, scraper: scraper, status_code: 1, created_at: LogLine::DISCARD_AFTER_DAYS.days.ago) }

        before do
          # Create log lines for each run
          successful_runs.each { |run| create(:log_line, run: run) }
          failed_runs.each { |run| create(:log_line, run: run) }
          create(:log_line, run: old_successful_run)
          create(:log_line, run: old_failed_run)
        end

        it "removes old log lines" do
          expect(Run.count).to be > 2 * more_than_keep_count
          initial_count = LogLine.count

          expect { Rake::Task["db:trim:log_lines"].execute }.to output(/Removed \d+ log lines/).to_stdout

          pending "FIXME: This is failing because of a bug in the test setup?"
          expect(LogLine.count).to be < initial_count
        end

        it "only preserves recent log lines as they have enough examples of both fails and successful" do
          Rake::Task["db:trim:log_lines"].execute

          # Should keep some lines from each run
          expect(LogLine.where(run: successful_runs).count).to be == more_than_keep_count
          pending "FIXME: This is failing because of a bug in the test setup?"
          expect(LogLine.where(run: failed_runs).count).to be == more_than_keep_count
          expect(LogLine.where(run: old_successful_run).count).to be == 0
          expect(LogLine.where(run: old_failed_run).count).to be == 0
        end
      end

      context "when there is not a plentiful mix of recent runs" do
        let!(:scraper) { create(:scraper) }
        let!(:more_than_keep_count) { LogLine::KEEP_AT_LEAST_COUNT_PER_STATUS + 2 }
        let!(:successful_run) { create(:run, scraper: scraper, status_code: 0, created_at: 1.hour.ago) }
        let!(:failed_run) { create(:run, scraper: scraper, status_code: 1, created_at: 1.hour.ago) }
        let!(:old_successful_runs) { more_than_keep_count.times.map { create(:run, scraper: scraper, status_code: 0, created_at: LogLine::DISCARD_AFTER_DAYS.days.ago) } }
        let!(:old_failed_runs) { more_than_keep_count.times.map { create(:run, scraper: scraper, status_code: 1, created_at: LogLine::DISCARD_AFTER_DAYS.days.ago) } }

        before do
          old_successful_runs.each { |run| create(:log_line, run: run) }
          old_failed_runs.each { |run| create(:log_line, run: run) }
          create(:log_line, run: successful_run)
          create(:log_line, run: failed_run)
        end

        it "removes old log lines" do
          initial_count = LogLine.count

          expect { Rake::Task["db:trim:log_lines"].execute }.to output(/Removed \d+ log lines/).to_stdout

          expect(LogLine.count).to be < initial_count
        end

        it "only preserves recent log lines as they have enough examples of both fails and successful" do
          Rake::Task["db:trim:log_lines"].execute

          # Should keep some lines from each run
          expect(LogLine.where(run: successful_run).count).to be == 1
          expect(LogLine.where(run: failed_run).count).to be == 1
          pending "FIXME: This is failing because of a bug in the test setup?"
          expect(LogLine.where(run: old_successful_runs).count).to be == LogLine::KEEP_AT_LEAST_COUNT_PER_STATUS - 1
          expect(LogLine.where(run: old_failed_runs).count).to be == LogLine::KEEP_AT_LEAST_COUNT_PER_STATUS - 1
        end
      end
    end

    # Remove connection_logs older than a year
    describe "trim:connection_logs" do
      let!(:old_log1) { create(:connection_log, created_at: 2.years.ago) }
      let!(:old_log2) { create(:connection_log, created_at: 13.months.ago) }
      let!(:recent_log) { create(:connection_log, created_at: 1.day.ago) }

      it "deletes old connection logs" do
        initial_count = ConnectionLog.count

        expect { Rake::Task["db:trim:connection_logs"].execute }
          .to output(/Removed \d+ connection_logs/).to_stdout

        expect(ConnectionLog.count).to be < initial_count
      end

      it "keeps recent connection logs" do
        Rake::Task["db:trim:connection_logs"].execute

        expect(ConnectionLog.exists?(recent_log.id)).to be true
      end

      it "removes connection logs older than 1 year" do
        Rake::Task["db:trim:connection_logs"].execute

        expect(ConnectionLog.exists?(old_log1.id)).to be false
        expect(ConnectionLog.exists?(old_log2.id)).to be false
      end
    end

    # Remove orphaned domains with no connection logs
    describe "trim:domains" do
      let!(:domain_with_logs) { create(:domain) }
      let!(:orphaned_domain) { create(:domain) }

      before do
        create(:connection_log, domain: domain_with_logs)
      end

      it "deletes orphaned domains" do
        initial_count = Domain.count

        expect { Rake::Task["db:trim:domains"].execute }
          .to output(/Deleted \d+ orphaned domains/).to_stdout

        expect(Domain.count).to be < initial_count
      end

      it "preserves domains with connection logs" do
        Rake::Task["db:trim:domains"].execute

        expect(Domain.exists?(domain_with_logs.id)).to be true
      end

      it "removes domains without connection logs" do
        Rake::Task["db:trim:domains"].execute

        expect(Domain.exists?(orphaned_domain.id)).to be false
      end
    end
  end
end
