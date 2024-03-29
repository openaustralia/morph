# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `CreateScraperWorker`.
# Please instead update this file by running `bin/tapioca dsl CreateScraperWorker`.

class CreateScraperWorker
  class << self
    sig { params(scraper_id: ::Integer, current_user_id: ::Integer, scraper_url: ::String).returns(String) }
    def perform_async(scraper_id, current_user_id, scraper_url); end

    sig do
      params(
        interval: T.any(DateTime, Time),
        scraper_id: ::Integer,
        current_user_id: ::Integer,
        scraper_url: ::String
      ).returns(String)
    end
    def perform_at(interval, scraper_id, current_user_id, scraper_url); end

    sig do
      params(
        interval: Numeric,
        scraper_id: ::Integer,
        current_user_id: ::Integer,
        scraper_url: ::String
      ).returns(String)
    end
    def perform_in(interval, scraper_id, current_user_id, scraper_url); end
  end
end
