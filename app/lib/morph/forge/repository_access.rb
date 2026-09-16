# typed: strict
# frozen_string_literal: true

module Morph
  module Forge
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

      # True when the repository can be cloned but the forge's API cannot be
      # reached, so a Run may go ahead on last-known permissions (ADR 0007).
      # Forges with one credential for both never say yes.
      sig { overridable.returns(T::Boolean) }
      def api_credential_missing?
        false
      end
    end
  end
end
