class ScraperAutoRunWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low

  def perform(scraper_id)
    scraper = Scraper.find(scraper_id)
    # Guard against more than one of a particular scraper running at the same time
    if scraper.runnable?
      run = scraper.runs.create(queued_at: Time.now, auto: true, owner_id: scraper.owner_id)
      run.synch_and_go!
    end
  end
end
