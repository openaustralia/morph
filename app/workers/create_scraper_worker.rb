# typed: strict
# frozen_string_literal: true

class CreateScraperWorker
  extend T::Sig

  include Sidekiq::Worker
  sidekiq_options backtrace: true

  sig { params(scraper_id: Integer, current_user_id: Integer, scraper_url: String).void }
  def perform(scraper_id, current_user_id, scraper_url)
    scraper = Scraper.find(scraper_id)
    current_user = User.find(current_user_id)

    # Checking progress here as a crude way to see if this background process previously
    # failed part of the way through.
    # TODO: Do this in a less hacky and more general way
    if scraper.create_scraper_progress.progress <= 20
      scraper.create_scraper_progress.update_progress("Creating GitHub repository", 20)
      current_user.github.create_repository(owner_nickname: scraper.owner.nickname, name: scraper.name, description: scraper.description, private: scraper.private)
    end

    # This block should happily run several times (after failures)
    scraper.create_scraper_progress.update_progress("Add scraper template", 40)
    files = scraper.original_language.scraper_templates.merge(
      ".gitignore" => "# Ignore output of scraper\n#{Morph::Database.sqlite_db_filename}\n",
      # TODO: Don't use hardcoded urls
      "README.md" => "This is a scraper that runs on [Morph](https://morph.io). To get started [see the documentation](https://morph.io/documentation)"
    )

    current_user.github.add_commit_to_root(scraper.full_name, files, "Add template for morph.io scraper")

    # This block should happily run several times (after failures)
    scraper.create_scraper_progress.update_progress("Get repository info", 60)
    scraper2 = Scraper.new_from_github(scraper.full_name, current_user)
    # Copy the new data across
    scraper.update(description: scraper2.description, github_id: scraper2.github_id,
                   owner_id: scraper2.owner_id, github_url: scraper2.github_url, git_url: scraper2.git_url)

    current_user.github.update_repo_homepage(scraper.full_name, scraper_url)

    # This block should happily run several times (after failures)
    scraper.create_scraper_progress.update_progress("Synching repository", 80)
    # TODO: We're ignoring any errors in the synchronising. Do we want to do this?
    SynchroniseRepoService.call(scraper)
    scraper.create_scraper_progress.finished
  end
end
