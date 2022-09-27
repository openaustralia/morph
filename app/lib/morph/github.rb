# typed: strict
# frozen_string_literal: true

module Morph
  # Service layer for talking to the Github API
  class Github
    extend T::Sig

    MORPH_GITHUB_APP_PRIVATE_KEY_PATH = "config/morph-github-app.private-key.pem"

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

    sig { returns(T.nilable(Integer)) }
    def self.app_id
      v = ENV.fetch("GITHUB_APP_ID", nil)
      return v if v.nil?

      v.to_i
    end

    sig { returns(T.nilable(String)) }
    def self.app_client_id
      ENV.fetch("GITHUB_APP_CLIENT_ID", nil)
    end

    sig { returns(T.nilable(String)) }
    def self.app_client_secret
      ENV.fetch("GITHUB_APP_CLIENT_SECRET", nil)
    end

    # Return a new github access token for a user given their old one.
    # Useful after #heartbleed.
    # No support for this method yet in octokit (it's brand new) so do
    # it ourselves
    sig { params(access_token: String).void }
    def self.reset_authorization(access_token)
      # POST https://api.github.com/applications/:client_id/tokens/:access_token
      conn = Faraday.new(url: "https://api.github.com") do |faraday|
        faraday.request :authorization, :basic, app_client_id, app_client_secret
        faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
      end
      res = conn.post("/applications/#{app_client_id}/tokens/#{access_token}")
      JSON.parse(res.body)["token"]
    end

    # Returns nicknames of github users who have contributed to a particular
    # repo
    sig { params(repo_full_name: String).returns(T::Array[String]) }
    def self.contributor_nicknames(repo_full_name)
      # This is not an action that is directly initiated by the user. It happens
      # whenever the github repo is synchronised (which happens on every run).
      # So we should authenticated the request using the application
      # which hopefully will not result in being rate limited.

      # I'm struggling to make a request with the application id and secret using octokit.
      # So, instead let's do it ourselves
      conn = Faraday.new(url: "https://api.github.com") do |faraday|
        faraday.request :authorization, :basic, app_client_id, app_client_secret
        faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
      end
      res = conn.get("/repos/#{repo_full_name}/contributors")
      contributors = JSON.parse(res.body)
      # github call returns nil if the git repo is completely empty
      contributors = [] unless contributors.is_a?(Array)
      contributors.map { |c| c["login"] }
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
        iss: app_id
      }

      JWT.encode(payload, private_key, "RS256")
    end

    sig { returns(Octokit::Client) }
    def self.jwt_client
      Octokit::Client.new(bearer_token: jwt)
    end

    sig { params(owner: Owner).returns(Integer) }
    def self.app_installation_id_for_owner(owner)
      # Curious. This single API endpoint seems to support both users and organizations despite there being
      # two separate API endpoints available. Hmmm... Well, let's just run with that then...
      # TODO: If there is no installation for the owner below raises Octokit::NotFound. Handle this!
      jwt_client.find_user_installation(owner.nickname).id
    end

    sig { params(owner: Owner).returns(String) }
    def self.app_installation_access_token(owner)
      jwt_client.create_app_installation_access_token(app_installation_id_for_owner(owner)).token
    end
  end
end
