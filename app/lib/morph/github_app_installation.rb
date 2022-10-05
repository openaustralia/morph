# typed: strict
# frozen_string_literal: true

module Morph
  class GithubAppInstallation
    extend T::Sig

    MORPH_GITHUB_APP_PRIVATE_KEY_PATH = "config/morph-github-app.private-key.pem"

    # rubocop:disable Lint/EmptyClass
    class AppInstallationNoAccessToRepo; end
    class NoAccessToRepo; end
    class NoAppInstallationForOwner; end
    # TODO: Split SynchroniseRepoError into more specific errors that mean something to users
    class SynchroniseRepoError; end
    # rubocop:enable Lint/EmptyClass

    sig { returns(String) }
    attr_reader :owner_nickname

    sig { params(owner_nickname: String).void }
    def initialize(owner_nickname)
      @owner_nickname = owner_nickname
    end

    sig { returns([String, T.nilable(NoAppInstallationForOwner)]) }
    def access_token
      @access_token ||= T.let(GithubAppInstallation.app_installation_access_token(owner_nickname), T.nilable([String, T.nilable(NoAppInstallationForOwner)]))
    end

    sig { params(repo_name: String).returns(T.nilable(T.any(Morph::GithubAppInstallation::NoAppInstallationForOwner, Morph::GithubAppInstallation::AppInstallationNoAccessToRepo))) }
    def confirm_has_access_to(repo_name)
      token, error = access_token
      return error if error

      GithubAppInstallation.confirm_app_installation_has_access_to(token, repo_name)
    end

    sig { params(repo_name: String).returns([T::Boolean, T.nilable(Morph::GithubAppInstallation::NoAppInstallationForOwner)]) }
    def repository_private?(repo_name)
      token, error = access_token
      return [false, error] if error

      result = GithubAppInstallation.repository_private?(token, repo_name)
      [result, nil]
    end

    # Returns Rugged::Repository
    sig { params(repo_path: String, git_url: String).returns(Rugged::Repository) }
    def self.synchronise_repo_ignore_submodules(repo_path, git_url)
      if File.exist?(repo_path) && !Dir.empty?(repo_path)
        Rails.logger.info "Updating git repo #{repo_path}..."
        repo = Rugged::Repository.new(repo_path)
        # Always update the remote with the latest git_url because the token in it expires quickly
        repo.remotes.set_url("origin", git_url)
        repo.fetch("origin")
        repo.reset("FETCH_HEAD", :hard)
        repo
      else
        Rails.logger.info "Cloning git repo #{git_url}..."
        Rugged::Repository.clone_at(git_url, repo_path)
      end
    end

    sig { params(app_installation_access_token: String, repo_path: String, git_url_https: String).returns(T.nilable(SynchroniseRepoError)) }
    def self.synchronise_repo(app_installation_access_token, repo_path, git_url_https)
      git_url = git_url_https_with_app_access(app_installation_access_token, git_url_https)
      repo = synchronise_repo_ignore_submodules(repo_path, git_url)
      repo.submodules.each do |submodule|
        submodule.init
        synchronise_repo_ignore_submodules(File.join(repo_path, submodule.path), submodule.url)
      end
      nil
    rescue Rugged::HTTPError, Rugged::SubmoduleError => e
      Rails.logger.warn "Error during Github.synchronise_repo: #{e}"
      # TODO: Give the user more detailed feedback about the problem
      # Indicate there was a problem
      SynchroniseRepoError.new
    end

    sig { params(app_installation_access_token: String, repo_name: String).returns(T::Boolean) }
    def self.app_installation_has_access_to?(app_installation_access_token, repo_name)
      client = Octokit::Client.new(bearer_token: app_installation_access_token)
      # TODO: Ensure auto_paginate is true
      client.list_app_installation_repositories.repositories.map(&:name).include?(repo_name)
    end

    sig { params(app_installation_access_token: String, repo_name: String).returns(T.nilable(AppInstallationNoAccessToRepo)) }
    def self.confirm_app_installation_has_access_to(app_installation_access_token, repo_name)
      if Morph::GithubAppInstallation.app_installation_has_access_to?(app_installation_access_token, repo_name)
        nil
      else
        Morph::GithubAppInstallation::AppInstallationNoAccessToRepo.new
      end
    end

    # Returns nicknames of github users who have contributed to a particular
    # repo
    sig { params(app_installation_access_token: String, repo_full_name: String).returns([T::Array[String], T.nilable(NoAccessToRepo)]) }
    def self.contributor_nicknames(app_installation_access_token, repo_full_name)
      client = Octokit::Client.new(bearer_token: app_installation_access_token)

      # TODO: Do we need to handle the situation of the git repo being completely empty?
      # In a previous version of this function the github call returned nil if the git repo is completely empty
      # Note if the app does not have access
      begin
        contributors = client.contributors(repo_full_name).map(&:login)
        [contributors, nil]
      rescue Octokit::NotFound
        [[], NoAccessToRepo.new]
      end
    end

    sig { params(app_installation_access_token: String, repo_full_name: String).returns(T::Boolean) }
    def self.repository_private?(app_installation_access_token, repo_full_name)
      client = Octokit::Client.new(bearer_token: app_installation_access_token)
      client.repository(repo_full_name).visibility == "private"
    end

    sig { returns(String) }
    def self.jwt
      # Private key contents
      private_pem = File.read(MORPH_GITHUB_APP_PRIVATE_KEY_PATH)
      private_key = OpenSSL::PKey::RSA.new(private_pem)

      # Generate the JWT
      payload = {
        # issued at time, 60 seconds in the past to allow for clock drift
        iat: Time.now.to_i - 60,
        # JWT expiration time (10 minute maximum)
        exp: Time.now.to_i + (10 * 60),
        # GitHub App's identifier
        iss: Morph::Environment.github_app_id
      }

      JWT.encode(payload, private_key, "RS256")
    end

    sig { returns(Octokit::Client) }
    def self.jwt_client
      Octokit::Client.new(bearer_token: jwt)
    end

    sig { params(owner_nickname: String).returns([Integer, T.nilable(NoAppInstallationForOwner)]) }
    def self.app_installation_id_for_owner(owner_nickname)
      # Curious. This single API endpoint seems to support both users and organizations despite there being
      # two separate API endpoints available. Hmmm... Well, let's just run with that then...
      # TODO: If there is no installation for the owner below raises Octokit::NotFound. Handle this!
      installion_id = jwt_client.find_user_installation(owner_nickname).id
      [installion_id, nil]
    rescue Octokit::NotFound
      [0, NoAppInstallationForOwner.new]
    end

    sig { params(owner_nickname: String).returns([String, T.nilable(NoAppInstallationForOwner)]) }
    def self.app_installation_access_token(owner_nickname)
      id, error = app_installation_id_for_owner(owner_nickname)
      case error
      when nil
        nil
      when NoAppInstallationForOwner
        return ["", error]
      else
        T.absurd(error)
      end

      token = jwt_client.create_app_installation_access_token(id).token
      [token, nil]
    end

    sig { params(app_installation_access_token: String, git_url_https: String).returns(String) }
    def self.git_url_https_with_app_access(app_installation_access_token, git_url_https)
      git_url_https.sub("https://", "https://x-access-token:#{app_installation_access_token}@")
    end
  end
end
