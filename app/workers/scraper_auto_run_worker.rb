# typed: false
# frozen_string_literal: true

class ScraperAutoRunWorker
  include Sidekiq::Worker
  sidekiq_options backtrace: true

  def perform(scraper_id)
    # Scraper might have been deleted after this job was created. So, check
    # for this
    scraper = Scraper.find_by(id: scraper_id)
    # Guard against more than one of a particular scraper running at the same time
    # And also double check that the scraper should be run automatically (in case it
    # has changed since it was queued)
    return unless scraper&.runnable? && scraper&.auto_run?

    # Raise an error so that when we're in read-only mode the jobs get requeued
    raise "Owner #{scraper.owner.nickname} doesn't have permission to create run" unless scraper.owner.ability.can? :create, Run

    run = scraper.runs.create(queued_at: Time.zone.now, auto: true, owner_id: scraper.owner_id)
    # Throw the actual run onto the background so it can be safely restarted
    RunWorker.perform_async(run.id)
  end
end
