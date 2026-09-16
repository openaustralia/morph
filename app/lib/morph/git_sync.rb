# typed: strict
# frozen_string_literal: true

module Morph
  # Brings a local clone up to date with its remote over https, using a
  # username and password (which for every forge is some kind of token).
  # Lifted from Morph::GithubAppInstallation so both forges share it.
  module GitSync
    extend T::Sig

    class Failed < StandardError; end

    # :nocov:
    # Mixes network git operations with the filesystem; covered by the
    # integration specs rather than unit tests (see TESTING.md).
    sig { params(repo_path: String, git_url_https: String, username: String, password: String).void }
    def self.synchronise(repo_path, git_url_https, username:, password:)
      repo = synchronise_ignore_submodules(repo_path, git_url_https, username: username, password: password)

      repo.submodules.each do |submodule|
        submodule.init
        synchronise_ignore_submodules(File.join(repo_path, submodule.path), submodule.url, username: username, password: password)
      end
    rescue Rugged::HTTPError, Rugged::SubmoduleError, Rugged::OSError => e
      Rails.logger.warn "Error during GitSync.synchronise: #{e}"
      raise Failed, e.message
    end

    sig { params(repo_path: String, git_url_https: String, username: String, password: String).returns(Rugged::Repository) }
    def self.synchronise_ignore_submodules(repo_path, git_url_https, username:, password:)
      git_url = with_credentials(git_url_https, username, password)

      if File.exist?(repo_path) && !Dir.empty?(repo_path)
        Rails.logger.info "Updating git repo #{repo_path}..."
        repo = Rugged::Repository.new(repo_path)
        # Always update the remote with the latest url because the token in it may have rotated
        repo.remotes.set_url("origin", git_url)
        repo.fetch("origin")
        repo.reset("FETCH_HEAD", :hard)
        repo
      else
        Rails.logger.info "Cloning git repo #{git_url_https}..."
        Rugged::Repository.clone_at(git_url, repo_path)
      end
    end
    # :nocov:

    # Only https URLs can carry credentials; anything else (a submodule over
    # ssh, say) is used as it stands.
    sig { params(git_url_https: String, username: String, password: String).returns(String) }
    def self.with_credentials(git_url_https, username, password)
      return git_url_https unless git_url_https.start_with?("https://")

      git_url_https.sub("https://", "https://#{ERB::Util.url_encode(username)}:#{ERB::Util.url_encode(password)}@")
    end
  end
end
