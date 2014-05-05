class CreateFromGithubWorker
  include Sidekiq::Worker
  include Sync::Actions

  def perform(scraper_id)
    scraper = Scraper.find(scraper_id)
    scraper.create_scraper_progress.update_attributes(message: "Synching repository", progress: 50)
    sync_update scraper
    scraper.synchronise_repo
    scraper.create_scraper_progress.update_attributes(message: nil, progress: 100)
    scraper.create_scraper_progress.destroy
    sync_update scraper
  end
end
