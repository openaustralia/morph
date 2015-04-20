class CreateScraperWorker
  include Sidekiq::Worker

  def perform(scraper_id, current_user_id, scraper_url)
    scraper = Scraper.find(scraper_id)
    current_user = User.find(current_user_id)

    # Checking progress here as a crude way to see if this background process previously
    # failed part of the way through.
    # TODO Do this in a less hacky and more general way
    if scraper.create_scraper_progress.progress <= 20
      scraper.create_scraper_progress.update("Creating Github repository", 20)
      repo = Morph::Github.create_repository(current_user, scraper.owner, scraper.name, description: scraper.description)
    end

    # This block should happily run several times (after failures)
    scraper.create_scraper_progress.update("Add scraper template", 40)
    files = scraper.original_language.scraper_templates(scraper.owner.buildpacks).merge(
      ".gitignore" => "# Ignore output of scraper\n#{Morph::Database.sqlite_db_filename}\n",
      # TODO Don't use hardcoded urls
      "README.md" => "This is a scraper that runs on [Morph](https://morph.io). To get started [see the documentation](https://morph.io/documentation)"
    )
    scraper.add_commit_to_root_on_github(current_user, files, "Add template for morph.io scraper")

    # This block should happily run several times (after failures)
    scraper.create_scraper_progress.update("Get repository info", 60)
    scraper2 = Scraper.new_from_github(scraper.full_name, current_user.octokit_client)
    # Copy the new data across
    scraper.update_attributes(description: scraper2.description, github_id: scraper2.github_id,
      owner_id: scraper2.owner_id, github_url: scraper2.github_url, git_url: scraper2.git_url)
    repo = current_user.octokit_client.edit_repository(scraper.full_name, homepage: scraper_url)

    # This block should happily run several times (after failures)
    scraper.create_scraper_progress.update("Synching repository", 80)
    scraper.synchronise_repo
    scraper.create_scraper_progress.finished
  end
end
