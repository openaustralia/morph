class ForkScraperwikiWorker
  include Sidekiq::Worker
  sidekiq_options backtrace: true

  def perform(scraper_id)
    Scraper.find(scraper_id).fork_from_scraperwiki!
  end
end
