# typed: strict
# frozen_string_literal: true

class SynchroniseRepoService
  extend T::Sig

  # Returns true if successfull
  # TODO: Return more helpful error messages
  sig { params(scraper: Scraper).returns(T::Boolean) }
  def self.call(scraper)
    url = scraper.git_url_https_with_app_access
    return false if url.nil?

    success = Morph::Github.synchronise_repo(scraper.repo_path, url)
    return false unless success

    scraper.update_repo_size
    scraper.update_contributors
    true
  rescue Grit::Git::CommandFailed => e
    Rails.logger.error "git command failed: #{e}"
    Rails.logger.error "Ignoring and moving onto the next one..."
    false
  end
end
