# typed: false
# frozen_string_literal: true

require "spec_helper"
require "rake"

RSpec.describe "rake db", type: :integration do # rubocop:disable RSpec/DescribeClass
  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  # Database Stats
  describe "db:stats" do
    it "runs without error" do
      expect { Rake::Task["db:stats"].invoke }.to output(/Table.*Count/).to_stdout
    end

    it "supports EXACT_COUNT environment variable" do
      stub_const("ENV", ENV.to_h.merge("EXACT_COUNT" => "1"))
      expect { Rake::Task["db:stats"].execute }.to output(/\(exact count\)/).to_stdout
    end
  end

  # Create a full backup of the database
  describe "db:backup" do
    before do
      allow(DbBackupUtils).to receive(:dump_compressed)
      allow(DbBackupUtils).to receive(:puts_help)
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:rm_f)
      allow(FileUtils).to receive(:mv)
      # Mock File.size? to return a value so it doesn't abort
      allow(File).to receive(:size?).and_return(100)
    end

    it "calls DbBackupUtils.dump_compressed" do
      Rake::Task["db:backup"].execute
      expect(DbBackupUtils).to have_received(:dump_compressed)
    end
  end

  # Create a filtered backup of the database for use in development
  describe "db:filtered_backup" do
    before do
      allow(DbBackupUtils).to receive(:dump_compressed)
      allow(DbBackupUtils).to receive(:dump_with_id_batches)
      allow(DbBackupUtils).to receive(:puts_help)
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:rm_f)
      allow(FileUtils).to receive(:mv)
      allow(File).to receive(:size?).and_return(100)
      # Mock database calls
      allow(Owner).to receive_message_chain(:where, :pluck).and_return([1]) # rubocop:disable RSpec/MessageChain
      allow(Owner).to receive_message_chain(:order, :limit, :pluck).and_return([2]) # rubocop:disable RSpec/MessageChain
      allow(Scraper).to receive_message_chain(:where, :pluck).and_return([10]) # rubocop:disable RSpec/MessageChain
      allow(Run).to receive_message_chain(:where, :where, :pluck).and_return([100]) # rubocop:disable RSpec/MessageChain
    end

    it "performs a filtered dump" do
      Rake::Task["db:filtered_backup"].execute
      expect(DbBackupUtils).to have_received(:dump_with_id_batches).at_least(:once)
    end
  end

  # Remove old log lines keeping some for both successful and erroneous runs
  describe "db:trim:log_lines" do
    let(:scraper) { instance_double(Scraper, full_name: "test_scraper", trim_log_lines: 5) }

    before do
      allow(Scraper).to receive(:order).and_return(Scraper)
      allow(Scraper).to receive(:find_each).and_yield(scraper)
      allow(Scraper).to receive(:count).and_return(1)
      allow(LogLine).to receive(:count).and_return(10)
    end

    it "calls trim_log_lines on scrapers" do
      expect { Rake::Task["db:trim:log_lines"].execute }.to output(/Removed 5 log lines/).to_stdout
      expect(scraper).to have_received(:trim_log_lines)
    end
  end

  # Remove connection_logs older than a year
  describe "db:trim:connection_logs" do
    before do
      allow(ConnectionLog).to receive(:count).and_return(10, 5)
      allow(ConnectionLog).to receive_message_chain(:order, :where, :limit, :delete_all).and_return(5, 0) # rubocop:disable RSpec/MessageChain
    end

    it "deletes old connection logs" do
      expect { Rake::Task["db:trim:connection_logs"].execute }.to output(/Removed 5 connection_logs/).to_stdout
    end
  end

  # Remove orphaned domains with no connection logs
  describe "db:trim:domains" do
    before do
      allow(Domain).to receive_message_chain(:left_joins, :where, :pluck).and_return([1, 2]) # rubocop:disable RSpec/MessageChain
      allow(Domain).to receive_message_chain(:where, :delete_all).and_return(2) # rubocop:disable RSpec/MessageChain
    end

    it "deletes orphaned domains" do
      expect { Rake::Task["db:trim:domains"].execute }.to output(/Deleted 2 orphaned domains/).to_stdout
    end
  end
end
