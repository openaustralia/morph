# typed: strict
# frozen_string_literal: true

module Morph
  # Service layer for talking to the Github API
  class Github
    extend T::Sig

    MORPH_GITHUB_APP_PRIVATE_KEY_PATH = "config/morph-github-app.private-key.pem"

    # rubocop:disable Lint/EmptyClass
    class NoAppInstallationForOwner; end
    class NoAccessToRepo; end
    class AppInstallationNoAccessToRepo; end
    # rubocop:enable Lint/EmptyClass

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

    # Returns true if everything worked
    sig { params(repo_path: String, git_url: String).returns(T::Boolean) }
    def self.synchronise_repo(repo_path, git_url)
      repo = synchronise_repo_ignore_submodules(repo_path, git_url)
      repo.submodules.each do |submodule|
        submodule.init
        synchronise_repo_ignore_submodules(File.join(repo_path, submodule.path), submodule.url)
      end
      true
    rescue Rugged::HTTPError, Rugged::SubmoduleError => e
      Rails.logger.warn "Error during Github.synchronise_repo: #{e}"
      # TODO: Give the user more detailed feedback about the problem
      # Indicate there was a problem
      false
    end

    # Will create a repository. Works for both an individual and an
    # organisation. Returns a repo
    sig { params(user: User, owner: Owner, name: String, description: T.nilable(String), private: T::Boolean).void }
    def self.create_repository(user:, owner:, name:, description:, private:)
      options = { description: description, private: private, auto_init: true }
      options[:organization] = owner.nickname if user != owner
      user.octokit_client.create_repository(name, options)
    end

    # Returns a list of all public repos. Works for both an individual and
    # an organization. List is sorted by push date
    sig { params(user: User, owner: Owner).returns(T::Array[T.untyped]) }
    def self.public_repos(user, owner)
      # TODO: Move this to an initializer
      Octokit.auto_paginate = true

      if user == owner
        user.octokit_client.repositories(owner.nickname,
                                         sort: :pushed, type: :public)
      else
        # This call doesn't seem to support sort by pushed.
        # So, doing it ourselves
        repos = user.octokit_client.organization_repositories(owner.nickname,
                                                              type: :public)
        repos.sort { |a, b| b.pushed_at.to_i <=> a.pushed_at.to_i }
      end
    end

    sig { params(user: User).returns(T.nilable(String)) }
    def self.primary_email(user)
      # TODO: If email isn't verified probably should not send email to it
      e = emails(user)
      e&.find(&:primary)&.email
    end

    # Needs user:email oauth scope for this to work
    # Will return nil if you don't have the right scope
    sig { params(user: User).returns(T.nilable(T::Array[T.untyped])) }
    def self.emails(user)
      user.octokit_client.emails(accept: "application/vnd.github.v3")
    rescue Octokit::NotFound, Octokit::Unauthorized
      nil
    end

    sig { params(app_installation_access_token: String, repo_name: String).returns(T::Boolean) }
    def self.app_installation_has_access_to?(app_installation_access_token, repo_name)
      client = Octokit::Client.new(bearer_token: app_installation_access_token)
      # TODO: Ensure auto_paginate is true
      client.list_app_installation_repositories.repositories.map(&:name).include?(repo_name)
    end

    # Returns nicknames of github users who have contributed to a particular
    # repo
    sig { params(owner_nickname: String, repo_name: String).returns([T::Array[String], T.nilable(T.any(NoAppInstallationForOwner, NoAccessToRepo))]) }
    def self.contributor_nicknames(owner_nickname, repo_name)
      # This is not an action that is directly initiated by the user. It happens
      # whenever the github repo is synchronised (which happens on every run).
      # So we should authenticate the request using the application
      token, error = app_installation_access_token(owner_nickname)
      case error
      when nil
        nil
      when NoAppInstallationForOwner
        return [[], error]
      else
        T.absurd(error)
      end

      client = Octokit::Client.new(bearer_token: token)

      # We're doing this so that we have consistent behaviour for the user with public repos. Otherwise
      # the user could run a public scraper even without the Github Morph app having access to the repo
      # connected with the scraper

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

    sig { params(repo_path: String).returns(String) }
    def self.current_revision_from_repo(repo_path)
      r = Rugged::Repository.new(repo_path)
      r.head.target_id
    end
  end
end
