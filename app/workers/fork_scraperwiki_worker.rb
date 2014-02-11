class ForkScraperwikiWorker
  include Sidekiq::Worker

  def perform(scraper_id)
    Scraper.find(scraper_id).fork_from_scraperwiki!
  end
end