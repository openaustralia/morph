class CreateScraperWorker
  include Sidekiq::Worker

  def perform(scraper_id, current_user_id, scraper_url)
    # TODO Handle this failing half way through and rerunning
    
    scraper = Scraper.find(scraper_id)
    current_user = User.find(current_user_id)

    scraper.create_scraper_progress.update("Creating Github repository", 20)
    repo = Morph::Github.create_repository(current_user, scraper.owner, scraper.name)
    files = {
      Morph::Language.language_to_scraper_filename(scraper.original_language.to_sym) => Morph::Language.default_scraper(scraper.original_language.to_sym),
      ".gitignore" => "# Ignore output of scraper\n#{Morph::Database.sqlite_db_filename}\n",
    }
    # TODO Don't use hardcoded urls
    files["README.md"] = "This is a scraper that runs on [Morph](https://morph.io). To get started [see the documentation](https://morph.io/documentation)"
    scraper.create_scraper_progress.update("Add scraper template", 40)
    scraper.add_commit_to_root_on_github(current_user, files, "Add template for Morph scraper")

    scraper.create_scraper_progress.update("Get repository info", 60)
    scraper2 = Scraper.new_from_github(repo.full_name, current_user.octokit_client)
    # Copy the new data across
    scraper.update_attributes(description: scraper2.description, github_id: scraper2.github_id,
      owner_id: scraper2.owner_id, github_url: scraper2.github_url, git_url: scraper2.git_url)
    repo = current_user.octokit_client.edit_repository(scraper.full_name, homepage: scraper_url)
    scraper.create_scraper_progress.update("Synching repository", 80)
    scraper.synchronise_repo
    scraper.create_scraper_progress.finished
  end
end
