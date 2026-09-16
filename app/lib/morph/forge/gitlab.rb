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

      # Until repository access lands, connecting GitLab means signing in with
      # it, which is what stores the identity morph.io will act as.
      sig { override.params(owner: Owner, scraper: T.nilable(Scraper)).returns(String) }
      def connect_url(owner, scraper = nil) # rubocop:disable Lint/UnusedMethodArgument
        Rails.application.routes.url_helpers.user_gitlab_omniauth_authorize_url
      end

      sig { override.params(owner: Owner).returns(T::Boolean) }
      def connected?(owner)
        owner.forge_identity(key).present?
      end

      sig { override.params(full_name: String).returns(T::Boolean) }
      def repository_exists?(full_name) # rubocop:disable Lint/UnusedMethodArgument
        false
      end

      sig { override.params(scraper: Scraper).returns(Forge::RepositoryAccess) }
      def repository_access(scraper)
        NotYetSupported.new(self, scraper)
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

      sig { params(owner: Owner).returns(String) }
      def login_of(owner)
        T.must(owner.forge_identity(key)).login
      end

      # Repository access on GitLab is not built yet. A scraper cannot be put on
      # GitLab until it is, so this is only reached if something has gone wrong.
      class NotYetSupported < Forge::RepositoryAccess
        extend T::Sig

        sig { params(forge: Gitlab, scraper: Scraper).void }
        def initialize(forge, scraper)
          super()
          @forge = forge
          @scraper = scraper
        end

        sig { override.returns(T.nilable(Error)) }
        def confirm_has_access
          @forge.error(:not_connected, @scraper)
        end

        sig { override.returns([T::Boolean, T.nilable(Error)]) }
        def private_repository
          [false, confirm_has_access]
        end

        sig { override.returns(T.nilable(Error)) }
        def synchronise_repo
          confirm_has_access
        end

        sig { override.returns([T::Array[Collaborator], T.nilable(Error)]) }
        def collaborators
          [[], confirm_has_access]
        end

        sig { override.returns([T.nilable(T::Array[String]), T.nilable(Error)]) }
        def contributor_logins
          [nil, confirm_has_access]
        end
      end
    end
  end
end
