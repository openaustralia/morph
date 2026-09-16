# typed: strict
# frozen_string_literal: true

class Scraper < ApplicationRecord
  # Everything about a Scraper that depends on which Forge its repository is
  # on: finding and describing the repository, building URLs there, and the
  # validations that call out to the forge before a scraper is created.
  module OnForge
    extend T::Sig
    extend T::Helpers
    extend ActiveSupport::Concern

    requires_ancestor { Scraper }

    included do
      # Make skipping the validations that call out to the forge an explicit choice
      class_attribute :skip_forge_validations, default: -> { Rails.env.test? }

      has_many :forge_credentials, dependent: :destroy
      validates :forge_key, inclusion: { in: ForgeIdentity::FORGES }
      validate :owner_is_on_forge, on: :create
      validate :not_used_on_forge, on: :create, if: proc { |s| s.forge_repo_id.blank? && s.name.present? }
      validate :forge_connected_to_owner, on: :create
      validate :forge_has_access_to_repo, on: :create
    end

    class_methods do
      extend T::Sig

      # Given a scraper name on github populates the fields for a morph.io scraper
      # but doesn't save it
      sig { params(full_name: String, user: User).returns(Scraper) }
      def new_from_github(full_name, user)
        new_from_forge(Morph::Forge.for("github"), full_name, user)
      end

      # Fills in a scraper from a repository that already exists on a forge, as
      # the given user can see it. Not saved. The owner is whichever Owner holds
      # the repository's owning account on that forge.
      sig { params(forge: Morph::Forge::Base, full_name: String, user: User).returns(Scraper) }
      def new_from_forge(forge, full_name, user)
        identity = T.must(user.forge_identity(forge.key))
        repo = T.must(forge.person_client(identity).repository(full_name))
        repo_owner = ForgeIdentity.find_by(forge_key: forge.key, login: repo.owner_login)&.owner || Owner.find_by!(nickname: repo.owner_login)
        Scraper.new(
          name: repo.name, full_name: "#{repo_owner.to_param}/#{repo.name}", description: repo.description,
          forge_key: forge.key, forge_repo_id: repo.id, owner_id: repo_owner.id,
          repo_url: repo.web_url, git_url: repo.clone_url, private: repo.private
        )
      end
    end

    # The repository this scraper runs from, as the forge describes it.
    sig { returns(Morph::Forge::Repository) }
    def forge_repository
      Morph::Forge::Repository.new(
        id: T.must(forge_repo_id), name: name, full_name: full_name, description: description, private: private,
        default_branch: default_branch, web_url: T.must(repo_url), clone_url: T.must(git_url),
        owner_login: T.must(owner).forge_identity(forge_key)&.login || T.must(T.must(owner).nickname)
      )
    end

    sig { returns(String) }
    def readme_url
      file_url(readme_filename)
    end

    sig { returns(Morph::Forge::Base) }
    def forge
      Morph::Forge.for(forge_key)
    end

    # The branch the forge shows by default, read from the local clone's HEAD
    # so no API call is needed. "main" until the repository has been cloned,
    # or if HEAD is detached.
    sig { returns(String) }
    def default_branch
      head = File.join(repo_path, ".git", "HEAD")
      return "main" unless File.exist?(head)

      File.read(head).strip[%r{\Aref: refs/heads/(.+)\z}, 1] || "main"
    end

    sig { params(file: String).returns(String) }
    def file_url(file)
      forge.file_url(self, file)
    end

    sig { returns(T.nilable(String)) }
    def main_scraper_file_url
      m = main_scraper_filename
      file_url(m) if m
    end

    # The https clone URL, whatever form the forge handed us the clone URL in:
    # GitHub's API gives git://, older records hold git@host:path, GitLab gives https.
    sig { returns(String) }
    def git_url_https
      url = T.must(git_url)
      case url
      when %r{\Agit://} then url.sub("git://", "https://")
      when /\Agit@([^:]+):(.+)\z/ then "https://#{Regexp.last_match(1)}/#{Regexp.last_match(2)}"
      else url
      end
    end

    private

    sig { void }
    def owner_is_on_forge
      return if owner.nil? || owner&.forge_identity(forge_key)

      errors.add(:owner_id, "#{T.must(owner).nickname} has no #{forge.name} account connected on morph.io")
    end

    sig { void }
    def not_used_on_forge
      return if self.class.skip_forge_validations || !forge.repository_exists?(full_name)

      errors.add(:name, "is already taken on #{forge.name}")
    end

    sig { void }
    def forge_connected_to_owner
      return if self.class.skip_forge_validations || forge.connected?(T.must(owner))

      # I18n.t doesn't support the _html suffix to make the string automatically html safe, so it is done by hand
      # rubocop:disable Rails/OutputSafety
      errors.add(:owner_id, forge.error(:not_connected, self).message_html.html_safe)
      # rubocop:enable Rails/OutputSafety
    end

    # When a scraper is created from a repository that already exists on the forge, forge_repo_id is populated
    # on creation and we check that morph.io can reach that specific repository
    sig { void }
    def forge_has_access_to_repo
      return if self.class.skip_forge_validations || forge_repo_id.blank?

      error = forge.repository_access(self).confirm_has_access
      return if error.nil?

      # rubocop:disable Rails/OutputSafety
      errors.add(:full_name, error.message_html.html_safe)
      # rubocop:enable Rails/OutputSafety
    end
  end
end
