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

    update_repo_size(scraper)
    update_contributors(scraper)
    true
  rescue Grit::Git::CommandFailed => e
    Rails.logger.error "git command failed: #{e}"
    Rails.logger.error "Ignoring and moving onto the next one..."
    false
  end

  sig { params(scraper: Scraper).void }
  def self.update_repo_size(scraper)
    scraper.update!(repo_size: directory_size(scraper.repo_path))
  end

  sig { params(scraper: Scraper).void }
  def self.update_contributors(scraper)
    nicknames = Morph::Github.contributor_nicknames(scraper.full_name)
    contributors = nicknames.map { |n| User.find_or_create_by_nickname(n) }
    # TODO: Use update! here?
    scraper.update(contributors: contributors)
  end

  # It seems silly implementing this
  sig { params(directory: String).returns(Integer) }
  def self.directory_size(directory)
    r = 0
    if File.exist?(directory)
      # Ick
      files = Dir.entries(directory)
      files.delete(".")
      files.delete("..")
      files.map { |f| File.join(directory, f) }.each do |f|
        s = File.lstat(f)
        r += if s.file?
               s.size
             else
               directory_size(f)
             end
      end
    end
    r
  end
end
