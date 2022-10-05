# typed: strict
# frozen_string_literal: true

class SynchroniseRepoService
  extend T::Sig

  # rubocop:disable Lint/EmptyClass
  class RepoNeedsToBePublic; end
  class RepoNeedsToBePrivate; end
  # rubocop:enable Lint/EmptyClass

  sig { params(scraper: Scraper).returns(T.nilable(T.any(Morph::GithubAppInstallation::NoAppInstallationForOwner, Morph::GithubAppInstallation::NoAccessToRepo, Morph::GithubAppInstallation::AppInstallationNoAccessToRepo, Morph::GithubAppInstallation::SynchroniseRepoError, RepoNeedsToBePublic, RepoNeedsToBePrivate))) }
  def self.call(scraper)
    # First check that the GitHub Morph app has access to the repository
    # We're doing this so that we have consistent behaviour for the user with public repos. Otherwise
    # the user could run a public scraper even without the Github Morph app having access to the repo
    # connected with the scraper
    installation = Morph::GithubAppInstallation.new(T.must(T.must(scraper.owner).nickname))

    token, error = installation.access_token
    return error if error

    error = installation.confirm_has_access_to(scraper.name)
    return error if error

    error = check_repository_visibility(installation, scraper)
    return error if error

    error = Morph::GithubAppInstallation.synchronise_repo(scraper.repo_path, git_url_https_with_app_access(token, scraper))
    return error if error

    update_repo_size(scraper)
    error = update_contributors(token, scraper)
    return error if error

    nil
  end

  sig { params(installation: Morph::GithubAppInstallation, scraper: Scraper).returns(T.nilable(T.any(RepoNeedsToBePublic, RepoNeedsToBePrivate, Morph::GithubAppInstallation::NoAppInstallationForOwner))) }
  def self.check_repository_visibility(installation, scraper)
    repository_private, error = installation.repository_private?(scraper.full_name)
    return error if error

    # No problem if the visibility of the scraper and the repository match
    return nil if repository_private == scraper.private?

    repository_private ? RepoNeedsToBePublic.new : RepoNeedsToBePrivate.new
  end

  sig { params(app_installation_access_token: String, scraper: Scraper).returns(String) }
  def self.git_url_https_with_app_access(app_installation_access_token, scraper)
    scraper.git_url_https.sub("https://", "https://x-access-token:#{app_installation_access_token}@")
  end

  sig { params(scraper: Scraper).void }
  def self.update_repo_size(scraper)
    scraper.update!(repo_size: directory_size(scraper.repo_path))
  end

  sig { params(app_installation_access_token: String, scraper: Scraper).returns(T.nilable(Morph::GithubAppInstallation::NoAccessToRepo)) }
  def self.update_contributors(app_installation_access_token, scraper)
    nicknames, error = Morph::GithubAppInstallation.contributor_nicknames(app_installation_access_token, scraper.full_name)
    return error if error

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
