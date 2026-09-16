# typed: strict
# frozen_string_literal: true

module Morph
  module Forge
    # The contract every forge adapter satisfies. spec/support/shared_examples/forge.rb
    # is the executable version of this file.
    class Base
      extend T::Sig
      extend T::Helpers
      abstract!

      # The value stored in forge_key columns.
      sig { abstract.returns(String) }
      def key; end

      # The name shown to people.
      sig { abstract.returns(String) }
      def name; end

      # Whether this deployment is set up to talk to the forge at all.
      sig { abstract.returns(T::Boolean) }
      def available?; end

      sig { abstract.params(owner: Owner).returns(String) }
      def owner_url(owner); end

      sig { abstract.params(scraper: Scraper, file: String).returns(String) }
      def file_url(scraper, file); end

      sig { abstract.params(scraper: Scraper, revision: String).returns(String) }
      def commit_url(scraper, revision); end

      # Where an owner goes to let morph.io reach their repositories on this
      # forge. On GitHub that is installing the Morph App.
      sig { abstract.params(owner: Owner, scraper: T.nilable(Scraper)).returns(String) }
      def connect_url(owner, scraper = nil); end

      # Whether morph.io can act on this owner's repositories at all. On GitHub
      # that means the Morph App is installed on the owner.
      sig { abstract.params(owner: Owner).returns(T::Boolean) }
      def connected?(owner); end

      # Whether a repository of this full name already exists on the forge,
      # checked before morph.io tries to create one.
      sig { abstract.params(full_name: String).returns(T::Boolean) }
      def repository_exists?(full_name); end

      # Reaches one scraper's repository as morph.io: access checks, clone,
      # visibility, collaborators and contributors.
      sig { abstract.params(scraper: Scraper).returns(RepositoryAccess) }
      def repository_access(scraper); end

      # The user-facing explanation of one kind of access failure for one scraper.
      sig { abstract.params(kind: Symbol, scraper: Scraper).returns(Error) }
      def error(kind, scraper); end

      # Whether this forge's access tokens run out and need refreshing.
      sig { abstract.returns(T::Boolean) }
      def tokens_expire?; end

      # Trades a refresh token for new tokens. Only called on forges whose
      # tokens expire.
      sig { abstract.params(refresh_token: String).returns(Tokens) }
      def refresh_tokens(refresh_token); end

      # What an OmniAuth callback hands us, in the shape ForgeIdentity stores.
      sig { params(auth: T.untyped).returns(Tokens) }
      def tokens_from_omniauth(auth)
        credentials = auth.credentials
        expires_at = credentials.expires_at ? Time.zone.at(credentials.expires_at) : nil
        Tokens.new(access_token: credentials.token, refresh_token: credentials.refresh_token, expires_at: expires_at)
      end

      # The login OmniAuth reports for this forge. GitHub calls it nickname,
      # GitLab username.
      sig { params(auth: T.untyped).returns(String) }
      def login_from_omniauth(auth)
        auth.info.nickname || auth.info.username
      end
    end

    # The credentials a forge issues for one identity.
    class Tokens < T::Struct
      const :access_token, String
      const :refresh_token, T.nilable(String)
      const :expires_at, T.nilable(Time)
    end

    # A permission set on one repository, in GitHub's five-level shape, which
    # is what the collaborations table stores. Other forges map onto it.
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

    # What a forge adapter returns from #repository_access.
    class RepositoryAccess
      extend T::Sig
      extend T::Helpers
      abstract!

      sig { abstract.returns(T.nilable(Error)) }
      def confirm_has_access; end

      sig { abstract.returns([T::Boolean, T.nilable(Error)]) }
      def private_repository; end

      sig { abstract.returns(T.nilable(Error)) }
      def synchronise_repo; end

      sig { abstract.returns([T::Array[Collaborator], T.nilable(Error)]) }
      def collaborators; end

      # Logins of everyone in the commit history, or nil when this forge
      # cannot say (see Contributor in CONTEXT.md).
      sig { abstract.returns([T.nilable(T::Array[String]), T.nilable(Error)]) }
      def contributor_logins; end
    end
  end
end
