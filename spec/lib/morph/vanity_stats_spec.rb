# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Morph::VanityStats do
  describe ".total_database_rows_updated_in_last_week" do
    context "with no runs" do
      it "returns zero" do
        expect(described_class.total_database_rows_updated_in_last_week).to eq(0)
      end
    end

    context "with runs in the last week" do
      let(:user) { create(:user) }
      let(:scraper) { create(:scraper, owner: user) }

      it "counts records_added from runs within the last week" do
        create(:run, scraper: scraper, owner: user, finished_at: 3.days.ago, records_added: 100, records_changed: 0)
        create(:run, scraper: scraper, owner: user, finished_at: 1.day.ago, records_added: 50, records_changed: 0)

        expect(described_class.total_database_rows_updated_in_last_week).to eq(150)
      end

      it "counts records_changed from runs within the last week" do
        create(:run, scraper: scraper, owner: user, finished_at: 3.days.ago, records_added: 0, records_changed: 75)
        create(:run, scraper: scraper, owner: user, finished_at: 1.day.ago, records_added: 0, records_changed: 25)

        expect(described_class.total_database_rows_updated_in_last_week).to eq(100)
      end

      it "sums both records_added and records_changed" do
        create(:run, scraper: scraper, owner: user, finished_at: 2.days.ago, records_added: 100, records_changed: 50)
        create(:run, scraper: scraper, owner: user, finished_at: 5.days.ago, records_added: 200, records_changed: 75)

        expect(described_class.total_database_rows_updated_in_last_week).to eq(425)
      end

      it "excludes runs finished 7 or more days ago" do
        create(:run, scraper: scraper, owner: user, finished_at: 7.days.ago + 10.seconds, records_added: 100, records_changed: 50)
        create(:run, scraper: scraper, owner: user, finished_at: 7.days.ago, records_added: 200, records_changed: 400)

        expect(described_class.total_database_rows_updated_in_last_week).to eq(150)
      end

      it "excludes runs with nil finished_at" do
        create(:run, scraper: scraper, owner: user, finished_at: nil, records_added: 100, records_changed: 50)
        create(:run, scraper: scraper, owner: user, finished_at: 3.days.ago, records_added: 25, records_changed: 10)

        expect(described_class.total_database_rows_updated_in_last_week).to eq(35)
      end

      it "handles nil values for records_added and records_changed" do
        create(:run, scraper: scraper, owner: user, finished_at: 3.days.ago, records_added: nil, records_changed: nil)
        create(:run, scraper: scraper, owner: user, finished_at: 1.day.ago, records_added: 50, records_changed: 25)

        expect(described_class.total_database_rows_updated_in_last_week).to eq(75)
      end

      it "handles zero values correctly" do
        create(:run, scraper: scraper, owner: user, finished_at: 3.days.ago, records_added: 0, records_changed: 0)

        expect(described_class.total_database_rows_updated_in_last_week).to eq(0)
      end
    end

    context "with maximal run" do
      let(:user) { create(:user, :maximal) }
      let(:scraper) { create(:scraper, :maximal, owner: user) }

      it "correctly sums records from a maximal run" do
        create(:run, :maximal, scraper: scraper, owner: user, finished_at: 1.day.ago)

        # Maximal run has records_added: 1000, records_changed: 200
        expect(described_class.total_database_rows_updated_in_last_week).to eq(1200)
      end
    end
  end

  describe ".total_pages_scraped_in_last_week" do
    context "with no connection logs" do
      it "returns zero" do
        expect(described_class.total_pages_scraped_in_last_week).to eq(0)
      end
    end

    # FIXME: When connection logs are implemented then test them
    # context "with connection logs in the last week" do
    #   let(:user) { create(:user) }
    #   let(:scraper) { create(:scraper, owner: user) }
    #   let(:run) { create(:run, scraper: scraper, owner: user) }
    #
    #   it "counts connection logs within the last week" do
    #     create(:connection_log, run: run, created_at: 3.days.ago)
    #     create(:connection_log, run: run, created_at: 1.day.ago)
    #     create(:connection_log, run: run, created_at: 5.days.ago)
    #
    #     expect(described_class.total_pages_scraped_in_last_week).to eq(3)
    #   end
    #
    #   it "excludes connection logs created more than 7 days ago" do
    #     create(:connection_log, run: run, created_at: 3.days.ago)
    #     create(:connection_log, run: run, created_at: 8.days.ago)
    #     create(:connection_log, run: run, created_at: 10.days.ago)
    #
    #     expect(described_class.total_pages_scraped_in_last_week).to eq(1)
    #   end
    #
    #   it "includes connection logs created exactly 7 days ago" do
    #     create(:connection_log, run: run, created_at: 7.days.ago)
    #
    #     expect(described_class.total_pages_scraped_in_last_week).to eq(1)
    #   end
    #
    #   it "handles multiple runs with connection logs" do
    #     run2 = create(:run, scraper: scraper, owner: user)
    #
    #     create(:connection_log, run: run, created_at: 1.day.ago)
    #     create(:connection_log, run: run, created_at: 2.days.ago)
    #     create(:connection_log, run: run2, created_at: 3.days.ago)
    #
    #     expect(described_class.total_pages_scraped_in_last_week).to eq(3)
    #   end
    # end
  end

  describe ".total_api_queries_in_last_week" do
    context "with no api queries" do
      it "returns zero" do
        expect(described_class.total_api_queries_in_last_week).to eq(0)
      end
    end

    context "with api queries in the last week" do
      let(:user) { create(:user) }
      let(:scraper) { create(:scraper, owner: user) }

      it "counts api queries within the last week" do
        create(:api_query, scraper: scraper, owner: user, created_at: 3.days.ago)
        create(:api_query, scraper: scraper, owner: user, created_at: 1.day.ago)
        create(:api_query, scraper: scraper, owner: user, created_at: 6.days.ago)

        expect(described_class.total_api_queries_in_last_week).to eq(3)
      end

      it "excludes api queries created more than 7 days ago" do
        create(:api_query, scraper: scraper, owner: user, created_at: 2.days.ago)
        create(:api_query, scraper: scraper, owner: user, created_at: 8.days.ago)
        create(:api_query, scraper: scraper, owner: user, created_at: 15.days.ago)

        expect(described_class.total_api_queries_in_last_week).to eq(1)
      end

      it "includes api queries created nearly 7 days ago" do
        create(:api_query, scraper: scraper, owner: user, created_at: 7.days.ago + 10.seconds)

        expect(described_class.total_api_queries_in_last_week).to eq(1)
      end

      it "handles multiple scrapers with api queries" do
        scraper2 = create(:scraper, owner: user)

        create(:api_query, scraper: scraper, owner: user, created_at: 1.day.ago)
        create(:api_query, scraper: scraper2, owner: user, created_at: 3.days.ago)
        create(:api_query, scraper: scraper, owner: user, created_at: 5.days.ago)

        expect(described_class.total_api_queries_in_last_week).to eq(3)
      end
    end

    context "with maximal api query" do
      let(:user) { create(:user, :maximal) }
      let(:scraper) { create(:scraper, :maximal, owner: user) }

      it "counts maximal api queries" do
        create(:api_query, :maximal, scraper: scraper, owner: user, created_at: 1.day.ago)

        expect(described_class.total_api_queries_in_last_week).to eq(1)
      end
    end
  end

  describe "combined scenarios" do
    let(:user) { create(:user) }
    let(:scraper) { create(:scraper, owner: user) }

    it "handles active scraper with runs and queries" do
      active_scraper = create(:active_scraper, owner: user)
      run = active_scraper.runs.first
      run.update!(finished_at: 2.days.ago, records_added: 100, records_changed: 50)

      # Currently, no connection logs are recorded.
      # create(:connection_log, run: run, created_at: 2.days.ago)
      create(:api_query, scraper: active_scraper, owner: user, created_at: 1.day.ago)

      expect(described_class.total_database_rows_updated_in_last_week).to eq(150)
      expect(described_class.total_pages_scraped_in_last_week).to eq(0)
      expect(described_class.total_api_queries_in_last_week).to eq(1)
    end

    it "correctly aggregates data across multiple scrapers and users" do
      user2 = create(:user)
      scraper2 = create(:scraper, owner: user2)

      run1 = create(:run, scraper: scraper, owner: user, finished_at: 1.day.ago,
                    records_added: 100, records_changed: 20)
      run2 = create(:run, scraper: scraper2, owner: user2, finished_at: 3.days.ago,
                    records_added: 50, records_changed: 30)

      # Currently, no connection logs are recorded.
      # create(:connection_log, run: run1, created_at: 1.day.ago)
      # create(:connection_log, run: run2, created_at: 3.days.ago)

      create(:api_query, scraper: scraper, owner: user, created_at: 2.days.ago)
      create(:api_query, scraper: scraper2, owner: user2, created_at: 4.days.ago)

      expect(described_class.total_database_rows_updated_in_last_week).to eq(200)
      expect(described_class.total_pages_scraped_in_last_week).to eq(0)
      expect(described_class.total_api_queries_in_last_week).to eq(2)
    end
  end
end
