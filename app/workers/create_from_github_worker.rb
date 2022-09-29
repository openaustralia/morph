# typed: strict
# frozen_string_literal: true

class CreateFromGithubWorker
  extend T::Sig

  include Sidekiq::Worker
  sidekiq_options backtrace: true

  sig { params(scraper_id: Integer).void }
  def perform(scraper_id)
    scraper = Scraper.find(scraper_id)
    scraper.create_scraper_progress.update_progress("Synching repository", 50)
    # TODO: We're ignoring any errors in the synchronising. Do we want to do this?
    SynchroniseRepoService.call(scraper)
    scraper.create_scraper_progress.finished
  end
end
