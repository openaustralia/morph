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

    sig { returns(T::Boolean) }
    def installed?
      _id, error = installation_id
      case error
      when nil
        true
      when NoAppInstallationForOwner
        false
      else
        T.absurd(error)
      end
    end

    sig { returns([Integer, T.nilable(NoAppInstallationForOwner)]) }
    def installation_id
      @installation_id ||= T.let(installation_id_no_caching, T.nilable([Integer, T.nilable(NoAppInstallationForOwner)]))
    end

    sig { returns([Integer, T.nilable(NoAppInstallationForOwner)]) }
    def installation_id_no_caching
      # Curious. This single API endpoint seems to support both users and organizations despite there being
      # two separate API endpoints available. Hmmm... Well, let's just run with that then...
      # TODO: If there is no installation for the owner below raises Octokit::NotFound. Handle this!
      installion_id = GithubAppInstallation.jwt_client.find_user_installation(owner_nickname).id
      [installion_id, nil]
    rescue Octokit::NotFound
      [0, NoAppInstallationForOwner.new]
    end

    sig { returns([String, T.nilable(NoAppInstallationForOwner)]) }
    def access_token
      @access_token ||= T.let(access_token_no_caching, T.nilable([String, T.nilable(NoAppInstallationForOwner)]))
    end

    sig { returns([String, T.nilable(NoAppInstallationForOwner)]) }
    def access_token_no_caching
      id, error = installation_id
      case error
      when nil
        nil
      when NoAppInstallationForOwner
        return ["", error]
      else
        T.absurd(error)
      end

      token = GithubAppInstallation.jwt_client.create_app_installation_access_token(id).token
      [token, nil]
    end

    sig { returns([Octokit::Client, T.nilable(NoAppInstallationForOwner)]) }
    def octokit_client
      token, error = access_token
      client = Octokit::Client.new(bearer_token: token)
      client.auto_paginate = true
      [client, error]
    end

    sig { params(repo_name: String).returns(T.nilable(T.any(NoAppInstallationForOwner, AppInstallationNoAccessToRepo))) }
    def confirm_has_access_to(repo_name)
      client, error = octokit_client
      return error if error

      if client.list_app_installation_repositories.repositories.map(&:name).include?(repo_name)
        nil
      else
        AppInstallationNoAccessToRepo.new
      end
    end

    sig { params(repo_name: String).returns([T::Boolean, T.nilable(NoAppInstallationForOwner)]) }
    def repository_private?(repo_name)
      client, error = octokit_client
      return [false, error] if error

      result = (client.repository("#{owner_nickname}/#{repo_name}").visibility == "private")
      [result, nil]
    end

    # TODO: Wouldn't it make sense to pass the base repo path, the repo name and instead work out the git_url_https from that?
    sig { params(repo_path: String, git_url_https: String).returns(T.nilable(T.any(NoAppInstallationForOwner, SynchroniseRepoError))) }
    def synchronise_repo(repo_path, git_url_https)
      repo, error = synchronise_repo_ignore_submodules(repo_path, git_url_https)
      return error if error

      repo.submodules.each do |submodule|
        submodule.init
        _repo, error2 = synchronise_repo_ignore_submodules(File.join(repo_path, submodule.path), submodule.url)
        return error2 if error2
      end
      nil
    rescue Rugged::HTTPError, Rugged::SubmoduleError => e
      Rails.logger.warn "Error during Github.synchronise_repo: #{e}"
      # TODO: Give the user more detailed feedback about the problem
      # Indicate there was a problem
      SynchroniseRepoError.new
    end

    # TODO: Wouldn't it make sense to pass the base repo path, the repo name and instead work out the git_url_https from that?
    sig { params(repo_path: String, git_url_https: String).returns([Rugged::Repository, T.nilable(NoAppInstallationForOwner)]) }
    def synchronise_repo_ignore_submodules(repo_path, git_url_https)
      token, error = access_token
      return [Rugged::Repository.new, error] if error

      # Allow git to access as the github application
      git_url = git_url_https.sub("https://", "https://x-access-token:#{token}@")

      repo = if File.exist?(repo_path) && !Dir.empty?(repo_path)
               Rails.logger.info "Updating git repo #{repo_path}..."
               repo = Rugged::Repository.new(repo_path)
               # Always update the remote with the latest git_url because the token in it expires quickly
               repo.remotes.set_url("origin", git_url)
               repo.fetch("origin")
               repo.reset("FETCH_HEAD", :hard)
               repo
             else
               Rails.logger.info "Cloning git repo #{git_url_https}..."
               Rugged::Repository.clone_at(git_url, repo_path)
             end
      [repo, nil]
    end

    # Returns nicknames of github users who have contributed to a particular repo
    sig { params(repo_name: String).returns([T::Array[String], T.nilable(T.any(NoAccessToRepo, NoAppInstallationForOwner))]) }
    def contributor_nicknames(repo_name)
      client, error = octokit_client
      return [[], error] if error

      # TODO: Do we need to handle the situation of the git repo being completely empty?
      # In a previous version of this function the github call returned nil if the git repo is completely empty
      # Note if the app does not have access
      begin
        contributors = client.contributors("#{owner_nickname}/#{repo_name}").map(&:login)
        [contributors, nil]
      rescue Octokit::NotFound
        [[], NoAccessToRepo.new]
      end
    end

    class Permissions < T::Struct
      const :pull, T::Boolean
      const :triage, T::Boolean
      const :push, T::Boolean
      const :maintain, T::Boolean
      const :admin, T::Boolean
    end

    class Collaborator < T::Struct
      const :login, String
      const :permissions, Permissions
    end

    sig { params(permissions: T.untyped).returns(Permissions) }
    def new_permissions(permissions)
      Permissions.new(
        pull: permissions.pull,
        triage: permissions.triage,
        push: permissions.push,
        maintain: permissions.maintain,
        admin: permissions.admin
      )
    end

    sig { params(collaborator: T.untyped).returns(Collaborator) }
    def new_collaborator(collaborator)
      Collaborator.new(
        login: collaborator.login,
        permissions: new_permissions(collaborator.permissions)
      )
    end

    # Returns list of collaborators on this repo including the permissions they have
    sig { params(repo_name: String).returns([T::Array[Collaborator], T.nilable(T.any(NoAccessToRepo, NoAppInstallationForOwner))]) }
    def collaborators(repo_name)
      client, error = octokit_client
      return [[], error] if error

      begin
        collaborators = client.collaborators("#{owner_nickname}/#{repo_name}").map do |c|
          new_collaborator(c)
        end
        [collaborators, nil]
      rescue Octokit::NotFound
        [[], NoAccessToRepo.new]
      end
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
  end
end
