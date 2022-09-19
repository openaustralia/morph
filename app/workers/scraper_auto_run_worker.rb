# typed: strict
# frozen_string_literal: true

class ScraperAutoRunWorker
  extend T::Sig

  include Sidekiq::Worker
  sidekiq_options backtrace: true

  sig { params(scraper_id: Integer).void }
  def perform(scraper_id)
    # Raise an error so that when we're in read-only mode the jobs get requeued
    raise "Can't auto-start runs when site is in read-only mode" if SiteSetting.read_only_mode

    # Scraper might have been deleted after this job was created. So, check
    # for this
    scraper = Scraper.find_by(id: scraper_id)
    # Guard against more than one of a particular scraper running at the same time
    # And also double check that the scraper should be run automatically (in case it
    # has changed since it was queued)
    return unless scraper&.runnable? && scraper.auto_run?

    run = scraper.runs.create(queued_at: Time.zone.now, auto: true, owner_id: scraper.owner_id)
    # Throw the actual run onto the background so it can be safely restarted
    RunWorker.perform_async(T.must(run.id))
  end
end
