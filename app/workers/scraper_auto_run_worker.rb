class ScraperAutoRunWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, backtrace: true

  def perform(scraper_id)
    scraper = Scraper.find(scraper_id)
    # Guard against more than one of a particular scraper running at the same time
    # And also double check that the scraper should be run automatically (in case it
    # has changed since it was queued)
    if scraper.runnable? && scraper.auto_run?
      if scraper.owner.ability.can? :create, Run
        run = scraper.runs.create(queued_at: Time.now, auto: true, owner_id: scraper.owner_id)
        run.synch_and_go!
      else
        # Raise an error so that when we're in read-only mode the jobs get requeued
        raise "Owner #{scraper.owner.nickname} doesn't have permission to create run"
      end
    end
  end
end
