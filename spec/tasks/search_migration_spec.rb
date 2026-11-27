# typed: false
# frozen_string_literal: true

require "spec_helper"
require "rake"

RSpec.describe "tasks" do # rubocop:disable RSpec/DescribeClass
  describe "search_migration", type: :integration do
    let(:good) { Morph::SearchMigration::Reindexer::ModelCount.new(name: "Scraper", database_count: 3, index_count: 3) }
    let(:short) { Morph::SearchMigration::Reindexer::ModelCount.new(name: "Owner", database_count: 5, index_count: 4) }
    let(:reindexer) { instance_double(Morph::SearchMigration::Reindexer) }

    before do
      Rails.application.load_tasks if Rake::Task.tasks.empty?
      allow(Morph::SearchMigration::Reindexer).to receive(:new).and_return(reindexer)
    end

    def run_task(name)
      Rake::Task[name].reenable
      Rake::Task[name].invoke
    end

    describe "app:search_migration:reindex" do
      it "reindexes and prints the report" do
        allow(reindexer).to receive(:reindex).and_return([good])

        expect { run_task("app:search_migration:reindex") }.to output(/RESULT: match/).to_stdout
      end

      it "exits 1 if the counts differ" do
        allow(reindexer).to receive(:reindex).and_return([good, short])

        expect { run_task("app:search_migration:reindex") }
          .to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }.and output(/RESULT: MISMATCH/).to_stdout
      end
    end

    describe "app:search_migration:verify" do
      before { allow(reindexer).to receive(:counts).and_return([good]) }

      it "prints counts without reindexing" do
        expect { run_task("app:search_migration:verify") }.to output(/RESULT: match/).to_stdout
      end

      it "compares with the old server's counts when given" do
        old = ENV.fetch("SOURCE_COUNTS", nil)
        ENV["SOURCE_COUNTS"] = "Scraper=9"
        expect { run_task("app:search_migration:verify") }
          .to raise_error(SystemExit).and output(/RESULT: MISMATCH/).to_stdout
      ensure
        ENV["SOURCE_COUNTS"] = old
      end
    end
  end
end
