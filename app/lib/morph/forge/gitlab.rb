# typed: strict
# frozen_string_literal: true

module Morph
  module Forge
    # GitLab (gitlab.com, or a self-hosted instance named by GITLAB_URL).
    # Sign-in and identities arrive first; reaching repositories comes with
    # the layered credentials of ADR 0007.
    class Gitlab < Base
      extend T::Sig

      sig { override.returns(String) }
      def key
        "gitlab"
      end

      sig { override.returns(String) }
      def name
        "GitLab"
      end

      sig { override.returns(T::Boolean) }
      def available?
        Morph::Environment.gitlab_configured?
      end

      sig { returns(String) }
      def base_url
        Morph::Environment.gitlab_url
      end

      sig { override.params(owner: Owner).returns(String) }
      def owner_url(owner)
        "#{base_url}/#{login_of(owner)}"
      end

      sig { override.params(scraper: Scraper, file: String).returns(String) }
      def file_url(scraper, file)
        "#{scraper.repo_url}/-/blob/#{scraper.default_branch}/#{file}"
      end

      sig { override.params(scraper: Scraper, revision: String).returns(String) }
      def commit_url(scraper, revision)
        "#{scraper.repo_url}/-/commit/#{revision}"
      end

      # Connecting GitLab means signing in with it (which stores the identity
      # morph.io can act as) and, for an Organization, someone with Owner on
      # the group creating morph.io's own tokens from the Organization page.
      sig { override.params(owner: Owner, scraper: T.nilable(Scraper)).returns(String) }
      def connect_url(owner, scraper = nil) # rubocop:disable Lint/UnusedMethodArgument
        Rails.application.routes.url_helpers.user_gitlab_omniauth_authorize_url
      end

      sig { override.params(owner: Owner).returns(T::Boolean) }
      def connected?(owner)
        owner.forge_identity(key).present?
      end

      # Unauthenticated lookups only see public projects, which is the same
      # limit GitHub's unauthenticated check has.
      sig { override.params(full_name: String).returns(T::Boolean) }
      def repository_exists?(full_name)
        !Morph::GitlabClient.new(access_token: "").project(full_name).nil?
      rescue Morph::GitlabClient::Unauthorized
        false
      end

      sig { override.params(scraper: Scraper).returns(Forge::RepositoryAccess) }
      def repository_access(scraper)
        RepositoryAccess.new(self, scraper)
      end

      # GitLab's cumulative roles onto the five permissions morph.io stores.
      # Maintainer maps to admin because on GitLab a Maintainer can change a
      # project's visibility and delete it, which is what admin gates here.
      sig { params(access_level: Integer).returns(Permissions) }
      def self.permissions_for(access_level)
        Permissions.new(
          pull: access_level >= Morph::GitlabClient::REPORTER,
          triage: access_level >= Morph::GitlabClient::DEVELOPER,
          push: access_level >= Morph::GitlabClient::DEVELOPER,
          maintain: access_level >= Morph::GitlabClient::MAINTAINER,
          admin: access_level >= Morph::GitlabClient::MAINTAINER
        )
      end

      sig { override.params(kind: Symbol, scraper: Scraper).returns(Error) }
      def error(kind, scraper)
        owner = T.must(scraper.owner)
        text = case kind
               when :not_connected
                 "#{owner.nickname} has no working GitLab sign-in on morph.io. Someone with access to this repository needs to sign in with GitLab at #{connect_url(owner, scraper)}"
               when :no_access_to_repo
                 "None of the GitLab accounts connected to morph.io can see the repository #{scraper.full_name}"
               when :sync_failed
                 "There was a problem getting the latest scraper code from GitLab"
               else
                 raise ArgumentError, "Unknown error kind #{kind.inspect}"
               end
        Error.new(kind: kind, message: text, message_html: ERB::Util.html_escape(text))
      end

      sig { override.returns(T::Boolean) }
      def tokens_expire?
        true
      end

      # GitLab invalidates the old refresh token as soon as it is used, so the
      # caller must store what comes back before anyone else asks (ForgeIdentity
      # holds a row lock while it does).
      sig { override.params(refresh_token: String).returns(Tokens) }
      def refresh_tokens(refresh_token)
        client = OAuth2::Client.new(Morph::Environment.gitlab_app_id, Morph::Environment.gitlab_app_secret, site: base_url)
        token = OAuth2::AccessToken.new(client, "", refresh_token: refresh_token).refresh!
        Tokens.new(access_token: token.token, refresh_token: token.refresh_token, expires_at: token.expires_at ? Time.zone.at(token.expires_at) : nil)
      end

      sig { override.params(identity: ForgeIdentity).returns(Forge::PersonClient) }
      def person_client(identity)
        PersonClient.new(identity)
      end

      sig { params(owner: Owner).returns(String) }
      def login_of(owner)
        T.must(owner.forge_identity(key)).login
      end

      sig { params(group: Morph::GitlabClient::Group).returns(Profile) }
      def self.profile_from_group(group)
        Profile.new(uid: group.id.to_s, login: group.path, name: group.name, email: nil, avatar_url: group.avatar_url,
                    blog: group.web_url, company: nil, location: nil)
      end

      sig { params(project: Morph::GitlabClient::Project).returns(Repository) }
      def self.repository_from(project)
        Repository.new(
          id: project.id, name: project.path, full_name: project.full_path, description: project.description,
          private: project.private, default_branch: project.default_branch,
          web_url: project.web_url, clone_url: project.http_url_to_repo, owner_login: project.namespace.path
        )
      end

      # Morph::GitlabClient with one person's OAuth token, refreshed as needed.
      class PersonClient < Forge::PersonClient
        extend T::Sig

        sig { params(identity: ForgeIdentity).void }
        def initialize(identity)
          super()
          @identity = identity
        end

        sig { override.params(owner: Owner).returns(T::Array[Repository]) }
        def repositories(owner)
          namespace = T.must(owner.forge_identity("gitlab"))
          projects = owner.is_a?(Organization) ? client.group_projects(namespace.uid.to_i) : client.user_projects(namespace.uid.to_i)
          projects.map { |project| Gitlab.repository_from(project) }
        end

        sig { override.params(full_name: String).returns(T.nilable(Repository)) }
        def repository(full_name)
          project = client.project(full_name)
          project && Gitlab.repository_from(project)
        end

        sig { override.params(owner: Owner, name: String, description: T.nilable(String), private: T::Boolean).returns(Repository) }
        def create_repository(owner:, name:, description:, private:)
          namespace_id = owner.is_a?(Organization) ? T.must(owner.forge_identity("gitlab")).uid.to_i : nil
          Gitlab.repository_from(client.create_project(path: name, description: description, private: private, namespace_id: namespace_id))
        end

        sig { override.params(repository: Repository, files: T::Hash[String, String], message: String).void }
        def commit_files(repository, files, message)
          client.commit_files(repository.id, branch: repository.default_branch || "main", message: message, files: files)
        end

        sig { override.params(repository: Repository, private: T::Boolean).void }
        def set_visibility(repository, private:)
          client.set_visibility(repository.id, private: private)
        end

        sig { override.returns(Profile) }
        def profile
          u = client.current_user
          Profile.new(uid: u.id.to_s, login: u.username, name: u.name, email: u.email, avatar_url: u.avatar_url,
                      blog: u.website_url, company: u.organization, location: u.location)
        end

        sig { override.returns(T::Array[Profile]) }
        def organizations
          client.groups.map { |g| Gitlab.profile_from_group(g) }
        end

        sig { override.params(login: String).returns(T.nilable(Profile)) }
        def organization(login)
          group = client.group(login)
          group && Gitlab.profile_from_group(group)
        rescue Morph::GitlabClient::Unauthorized, Morph::GitlabClient::Forbidden
          nil
        end

        private

        sig { returns(Morph::GitlabClient) }
        def client
          Morph::GitlabClient.new(access_token: T.must(@identity.fresh_access_token))
        end
      end
    end
  end
end
