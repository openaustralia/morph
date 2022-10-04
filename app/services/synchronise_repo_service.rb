# typed: strict
# frozen_string_literal: true

class SynchroniseRepoService
  extend T::Sig

  # Says that the morph github app has not been installed on the user or organization
  class NoAppInstallationForOwner < StandardError; end
  class SynchroniseRepoError < StandardError; end

  # Returns true if successfull
  # TODO: Return more helpful error messages
  sig { params(scraper: Scraper).returns(T.nilable(T.any(Morph::Github::NoAppInstallationForOwner, SynchroniseRepoError))) }
  def self.call(scraper)
    url, error = git_url_https_with_app_access(scraper)
    case error
    when nil
      nil
    when Morph::Github::NoAppInstallationForOwner
      return error
    else
      T.absurd(error)
    end

    success = Morph::Github.synchronise_repo(scraper.repo_path, url)
    return SynchroniseRepoError.new unless success

    update_repo_size(scraper)
    update_contributors(scraper)
    nil
  end

  # This is all a bit hacky
  # TODO: Tidy up
  sig { params(scraper: Scraper).returns([String, T.nilable(Morph::Github::NoAppInstallationForOwner)]) }
  def self.git_url_https_with_app_access(scraper)
    token, error = Morph::Github.app_installation_access_token(T.must(T.must(scraper.owner).nickname))
    case error
    when nil
      nil
    when Morph::Github::NoAppInstallationForOwner
      return ["", error]
    else
      T.absurd(error)
    end

    url = scraper.git_url_https.sub("https://", "https://x-access-token:#{token}@")
    [url, nil]
  end

  sig { params(scraper: Scraper).void }
  def self.update_repo_size(scraper)
    scraper.update!(repo_size: directory_size(scraper.repo_path))
  end

  sig { params(scraper: Scraper).void }
  def self.update_contributors(scraper)
    nicknames = Morph::Github.contributor_nicknames(T.must(T.must(scraper.owner).nickname), scraper.name)
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
