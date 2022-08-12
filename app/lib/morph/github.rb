# typed: true
# frozen_string_literal: true

module Morph
  # Service layer for talking to the Github API
  class Github
    extend T::Sig

    # Returns Rugged::Repository
    sig { params(repo_path: String, git_url: String).returns(Rugged::Repository) }
    def self.synchronise_repo_ignore_submodules(repo_path, git_url)
      if File.exist?(repo_path) && !Dir.empty?(repo_path)
        Rails.logger.info "Updating git repo #{repo_path}..."
        repo = Rugged::Repository.new(repo_path)
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
    rescue Rugged::HTTPError
      # Indicate there was a problem
      false
    end

    # Will create a repository. Works for both an individual and an
    # organisation. Returns a repo
    sig { params(user: User, owner: Owner, name: String, options: T::Hash[Symbol, T.untyped]).void }
    def self.create_repository(user, owner, name, options = {})
      if user == owner
        user.octokit_client.create_repository(
          name,
          options.merge(auto_init: true)
        )
      else
        user.octokit_client.create_repository(
          name,
          options.merge(auto_init: true, organization: owner.nickname)
        )
      end
    end

    # Returns a list of all public repos. Works for both an individual and
    # an organization. List is sorted by push date
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
    def self.emails(user)
      user.octokit_client.emails(accept: "application/vnd.github.v3")
    rescue Octokit::NotFound, Octokit::Unauthorized
      nil
    end

    # Return a new github access token for a user given their old one.
    # Useful after #heartbleed.
    # No support for this method yet in octokit (it's brand new) so do
    # it ourselves
    sig { params(access_token: String).void }
    def self.reset_authorization(access_token)
      # POST https://api.github.com/applications/:client_id/tokens/:access_token
      client_id = ENV.fetch("GITHUB_APP_CLIENT_ID", nil)
      client_secret = ENV.fetch("GITHUB_APP_CLIENT_SECRET", nil)

      conn = Faraday.new(url: "https://api.github.com") do |faraday|
        faraday.request :authorization, :basic, client_id, client_secret
        faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
      end
      res = conn.post("/applications/#{client_id}/tokens/#{access_token}")
      JSON.parse(res.body)["token"]
    end

    # Returns nicknames of github users who have contributed to a particular
    # repo
    def self.contributor_nicknames(repo_full_name)
      # This is not an action that is directly initiated by the user. It happens
      # whenever the github repo is synchronised (which happens on every run).
      # So we should authenticated the request using the application
      # which hopefully will not result in being rate limited.

      # I'm struggling to make a request with the application id and secret using octokit.
      # So, instead let's do it ourselves
      client_id = ENV.fetch("GITHUB_APP_CLIENT_ID", nil)
      client_secret = ENV.fetch("GITHUB_APP_CLIENT_SECRET", nil)

      conn = Faraday.new(url: "https://api.github.com") do |faraday|
        faraday.request :authorization, :basic, client_id, client_secret
        faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
      end
      res = conn.get("/repos/#{repo_full_name}/contributors")
      contributors = JSON.parse(res.body)
      # github call returns nil if the git repo is completely empty
      contributors = [] unless contributors.is_a?(Array)
      contributors.map { |c| c["login"] }
    end
  end
end
