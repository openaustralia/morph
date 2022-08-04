# typed: true
# frozen_string_literal: true

module Morph
  # Calculate vanity stats that we show on the landing page
  class VanityStats
    # Include rows that have been changed and created
    def self.total_database_rows_updated_in_last_week
      Run.where("finished_at > ?", 7.days.ago).sum(:records_added) +
        Run.where("finished_at > ?", 7.days.ago).sum(:records_changed)
    end

    def self.total_pages_scraped_in_last_week
      ConnectionLog.where("created_at > ?", 7.days.ago).count
    end

    def self.total_api_queries_in_last_week
      ApiQuery.where("created_at > ?", 7.days.ago).count
    end

    # TODO: Speed this up by storing a cached version of this information
    # in the database
    def self.total_database_rows
      Scraper.all.to_a.sum(&:sqlite_total_rows)
    end

    # Round down to the nearest million
    def self.rounded_total_database_rows_in_millions
      (total_database_rows / 1_000_000.0).floor
    end
  end
end
