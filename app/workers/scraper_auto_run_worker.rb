class ScraperAutoRunWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low

  def perform(scraper_id)
    scraper = Scraper.find(scraper_id)
    # Guard against more than one of a particular scraper running at the same time
    # And also double check that the scraper should be run automatically (in case it
    # has changed since it was queued)
    if scraper.runnable? && scraper.auto_run?
      run = scraper.runs.create(queued_at: Time.now, auto: true, owner_id: scraper.owner_id)
      run.synch_and_go!
    end
  end
end
