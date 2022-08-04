# typed: false
# frozen_string_literal: true

class CreateFromGithubWorker
  include Sidekiq::Worker
  sidekiq_options backtrace: true

  def perform(scraper_id)
    scraper = Scraper.find(scraper_id)
    scraper.create_scraper_progress.update_progress("Synching repository", 50)
    scraper.synchronise_repo
    scraper.create_scraper_progress.finished
  end
end
