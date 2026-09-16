# typed: strict
# frozen_string_literal: true

module Morph
  module Forge
    # What a forge adapter returns from #person_client.
    class PersonClient
      extend T::Sig
      extend T::Helpers
      abstract!

      # Repositories morph.io could run as scrapers, owned by `owner` (the
      # person themselves or an Organization they belong to), most recently
      # active first.
      sig { abstract.params(owner: Owner).returns(T::Array[Repository]) }
      def repositories(owner); end

      sig { abstract.params(full_name: String).returns(T.nilable(Repository)) }
      def repository(full_name); end

      sig { abstract.params(owner: Owner, name: String, description: T.nilable(String), private: T::Boolean).returns(Repository) }
      def create_repository(owner:, name:, description:, private:); end

      # Adds files to the repository's default branch in one commit.
      sig { abstract.params(repository: Repository, files: T::Hash[String, String], message: String).void }
      def commit_files(repository, files, message); end

      sig { abstract.params(repository: Repository, private: T::Boolean).void }
      def set_visibility(repository, private:); end

      # Points the repository's homepage at its morph.io page, on forges
      # that have one. Others do nothing.
      sig { overridable.params(repository: Repository, url: String).void }
      def set_homepage(repository, url); end

      # The person's own account.
      sig { abstract.returns(Profile) }
      def profile; end

      # The organisations (GitHub) or top-level groups (GitLab) the person
      # belongs to, as morph.io would make Organizations of them.
      sig { abstract.returns(T::Array[Profile]) }
      def organizations; end

      # One organisation, as the person can see it. Nil if they cannot.
      sig { abstract.params(login: String).returns(T.nilable(Profile)) }
      def organization(login); end
    end
  end
end
