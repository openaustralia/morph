# typed: strict
# frozen_string_literal: true

class SynchroniseRepoService
  extend T::Sig

  # Says that the morph github app has not been installed on the user or organization
  class NoAppInstallationForOwner < StandardError; end
  class SynchroniseRepoError < StandardError; end

  # Returns true if successfull
  # TODO: Return more helpful error messages
  sig { params(scraper: Scraper).returns(T.nilable(T.any(Morph::Github::NoAppInstallationForOwner, Morph::Github::NoAccessToRepo, Morph::Github::AppInstallationNoAccessToRepo, SynchroniseRepoError))) }
  def self.call(scraper)
    # First check that the GitHub Morph app has access to the repository
    # We're doing this so that we have consistent behaviour for the user with public repos. Otherwise
    # the user could run a public scraper even without the Github Morph app having access to the repo
    # connected with the scraper

    token, error = Morph::Github.app_installation_access_token(T.must(T.must(scraper.owner).nickname))
    case error
    when nil
      nil
    when Morph::Github::NoAppInstallationForOwner
      return error
    else
      T.absurd(error)
    end
    return Morph::Github::AppInstallationNoAccessToRepo.new unless Morph::Github.app_installation_has_access_to?(token, scraper.name)

    url = git_url_https_with_app_access(token, scraper)

    success = Morph::Github.synchronise_repo(scraper.repo_path, url)
    return SynchroniseRepoError.new unless success

    update_repo_size(scraper)
    error = update_contributors(token, scraper)
    case error
    when nil
      nil
    when Morph::Github::NoAccessToRepo
      error
    else
      T.absurd(error)
    end
  end

  sig { params(app_installation_access_token: String, scraper: Scraper).returns(String) }
  def self.git_url_https_with_app_access(app_installation_access_token, scraper)
    scraper.git_url_https.sub("https://", "https://x-access-token:#{app_installation_access_token}@")
  end

  sig { params(scraper: Scraper).void }
  def self.update_repo_size(scraper)
    scraper.update!(repo_size: directory_size(scraper.repo_path))
  end

  sig { params(app_installation_access_token: String, scraper: Scraper).returns(T.nilable(Morph::Github::NoAccessToRepo)) }
  def self.update_contributors(app_installation_access_token, scraper)
    nicknames, error = Morph::Github.contributor_nicknames(app_installation_access_token, T.must(T.must(scraper.owner).nickname), scraper.name)
    case error
    when nil
      nil
    when Morph::Github::NoAccessToRepo
      return error
    else
      T.absurd(error)
    end

    contributors = nicknames.map { |n| User.find_or_create_by!(nickname: n) }
    scraper.update!(contributors: contributors)
    nil
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
