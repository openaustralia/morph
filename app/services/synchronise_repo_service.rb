# typed: strict
# frozen_string_literal: true

# Brings a Scraper's local clone up to date with its repository on the forge,
# and mirrors what the forge knows about the repository: size, contributors,
# collaborators. Returns an error object rather than raising, so the Runner
# can turn it into a failed Run with a message the user can act on.
class SynchroniseRepoService
  extend T::Sig

  # rubocop:disable Lint/EmptyClass
  class RepoNeedsToBePublic; end
  class RepoNeedsToBePrivate; end
  # rubocop:enable Lint/EmptyClass

  sig { params(scraper: Scraper).returns(T.nilable(T.any(Morph::Forge::Error, RepoNeedsToBePublic, RepoNeedsToBePrivate))) }
  def self.call(scraper)
    access = scraper.forge.repository_access(scraper)

    # Checked even for public repositories, so that a public scraper cannot be run
    # unless morph.io has been given access to its repository the same way as a
    # private one would need. It keeps the experience consistent.
    error = access.confirm_has_access
    return error if error

    error = check_repository_visibility(access, scraper)
    return error if error

    error = access.synchronise_repo
    return error if error

    update_repo_size(scraper)
    error = update_contributors(access, scraper)
    return error if error

    update_collaborators(access, scraper)
  end

  sig { params(access: Morph::Forge::RepositoryAccess, scraper: Scraper).returns(T.nilable(T.any(RepoNeedsToBePublic, RepoNeedsToBePrivate, Morph::Forge::Error))) }
  def self.check_repository_visibility(access, scraper)
    repository_private, error = access.private_repository
    return error if error

    # No problem if the visibility of the scraper and the repository match
    return nil if repository_private == scraper.private?

    repository_private ? RepoNeedsToBePublic.new : RepoNeedsToBePrivate.new
  end

  sig { params(scraper: Scraper).void }
  def self.update_repo_size(scraper)
    scraper.update!(repo_size: directory_size(scraper.repo_path))
  end

  # Contributors are left as they were when the forge cannot say who they are
  # (see Contributor in CONTEXT.md).
  sig { params(access: Morph::Forge::RepositoryAccess, scraper: Scraper).returns(T.nilable(Morph::Forge::Error)) }
  def self.update_contributors(access, scraper)
    logins, error = access.contributor_logins
    return error if error
    return nil if logins.nil?

    contributors = logins.map { |n| User.find_or_create_by!(nickname: n) }
    scraper.update!(contributors: contributors)
    nil
  end

  sig { params(access: Morph::Forge::RepositoryAccess, scraper: Scraper).returns(T.nilable(Morph::Forge::Error)) }
  def self.update_collaborators(access, scraper)
    collaborators, error = access.collaborators
    return error if error

    collaborations = collaborators.map do |c|
      u = User.find_or_create_by!(nickname: c.login)
      collaboration = scraper.collaborations.find_or_initialize_by(owner: u)
      collaboration.update!(c.permissions.serialize)
      collaboration
    end
    scraper.update!(collaborations: collaborations)
    nil
  end

  # It seems silly implementing this
  sig { params(directory: String).returns(Integer) }
  def self.directory_size(directory)
    r = 0
    if File.exist?(directory)
      # Ick
      files = Dir.entries(directory)
      files.delete(".")
      files.delete("..")
      files.map { |f| File.join(directory, f) }.each do |f|
        s = File.lstat(f)
        r += if s.file?
               s.size
             else
               directory_size(f)
             end
      end
    end
    r
  end
end
