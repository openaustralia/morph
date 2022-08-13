# typed: strict
# frozen_string_literal: true

module Morph
  # Calculate vanity stats that we show on the landing page
  class VanityStats
    extend T::Sig

    # Include rows that have been changed and created
    sig { returns(Integer) }
    def self.total_database_rows_updated_in_last_week
      Run.where("finished_at > ?", 7.days.ago).sum(:records_added) +
        Run.where("finished_at > ?", 7.days.ago).sum(:records_changed)
    end

    sig { returns(Integer) }
    def self.total_pages_scraped_in_last_week
      ConnectionLog.where("created_at > ?", 7.days.ago).count
    end

    sig { returns(Integer) }
    def self.total_api_queries_in_last_week
      ApiQuery.where("created_at > ?", 7.days.ago).count
    end
  end
end
