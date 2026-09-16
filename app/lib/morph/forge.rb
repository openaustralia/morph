# typed: strict
# frozen_string_literal: true

module Morph
  # A Forge is a service that hosts git repositories and authenticates the
  # people who own them: GitHub or GitLab (see CONTEXT.md). Everything that
  # differs between forges lives behind an adapter here, so the rest of
  # morph.io asks `scraper.forge` rather than assuming GitHub.
  module Forge
    extend T::Sig

    # Something that stopped morph.io reaching a repository. Returned, not
    # raised, matching the Go-style [result, error] convention used by
    # Morph::GithubAppInstallation. The forge that produced it writes the
    # message, because what the user has to do about it is forge-specific.
    class Error < T::Struct
      KINDS = T.let(%i[not_connected no_access_to_repo sync_failed].freeze, T::Array[Symbol])

      const :kind, Symbol
      const :message, String
      const :message_html, String
    end

    sig { returns(T::Array[Base]) }
    def self.all
      [Github.new, Gitlab.new]
    end

    # The forges a person can sign in with here, given what is configured.
    sig { returns(T::Array[Base]) }
    def self.available
      all.select(&:available?)
    end

    sig { params(key: String).returns(Base) }
    def self.for(key)
      all.find { |forge| forge.key == key } || raise(ArgumentError, "Unknown forge #{key.inspect}")
    end
  end
end
