# typed: strict
# frozen_string_literal: true

module Morph
  module Forge
    # GitHub, reached as the Morph GitHub App (Morph::GithubAppInstallation)
    # for repository access and as the signed-in user (Morph::Github) for
    # everything done on their behalf.
    class Github < Base
      extend T::Sig

      sig { override.returns(String) }
      def key
        "github"
      end

      sig { override.returns(String) }
      def name
        "GitHub"
      end

      sig { override.returns(T::Boolean) }
      def available?
        true
      end

      sig { override.params(owner: Owner).returns(String) }
      def owner_url(owner)
        "https://github.com/#{login_of(owner)}"
      end

      sig { override.params(scraper: Scraper, file: String).returns(String) }
      def file_url(scraper, file)
        "#{scraper.repo_url}/blob/#{scraper.default_branch}/#{file}"
      end

      sig { override.params(scraper: Scraper, revision: String).returns(String) }
      def commit_url(scraper, revision)
        "#{scraper.repo_url}/commit/#{revision}"
      end

      # Installing the Morph GitHub App on the owner, suggesting the repositories
      # morph.io already knows about so the person does not have to find them.
      sig { override.params(owner: Owner, scraper: T.nilable(Scraper)).returns(String) }
      def connect_url(owner, scraper = nil)
        repository_ids = scraper ? scraper.forge_repo_id : owner.scrapers.map(&:forge_repo_id)
        params = { suggested_target_id: owner.github_identity&.uid, repository_ids: repository_ids }
        "https://github.com/apps/#{Morph::Environment.github_app_name}/installations/new/permissions?#{params.to_query}"
      end

      sig { override.params(owner: Owner).returns(T::Boolean) }
      def connected?(owner)
        Morph::GithubAppInstallation.new(T.must(owner.nickname)).installed?
      end

      sig { override.params(full_name: String).returns(T::Boolean) }
      def repository_exists?(full_name)
        Octokit.client.repository?(full_name)
      end

      sig { override.params(scraper: Scraper).returns(Forge::RepositoryAccess) }
      def repository_access(scraper)
        RepositoryAccess.new(self, scraper)
      end

      sig { override.params(kind: Symbol, scraper: Scraper).returns(Error) }
      def error(kind, scraper)
        owner = T.must(scraper.owner)
        install_url = connect_url(owner, scraper)
        why_url = Rails.application.routes.url_helpers.github_app_documentation_index_url
        case kind
        when :not_connected
          Error.new(
            kind: kind,
            message: "Please install the Morph Github App on #{owner.nickname} so that Morph can access this repository on GitHub. Please go to #{install_url}\n\nWhy? See #{why_url}",
            message_html: I18n.t("activerecord.errors.models.scraper.no_app_installation_for_owner", install_url: install_url, why_url: why_url, owner: owner.nickname)
          )
        when :no_access_to_repo
          Error.new(
            kind: kind,
            message: "The Morph Github App installed on #{owner.nickname} needs access to the repository #{scraper.name}. Please go to #{install_url}\n\nWhy? See #{why_url}",
            message_html: I18n.t("activerecord.errors.models.scraper.app_installation_no_access_to_repo", install_url: install_url, why_url: why_url, owner: owner.nickname, repo: scraper.name)
          )
        when :sync_failed
          text = "There was a problem getting the latest scraper code from GitHub"
          Error.new(kind: kind, message: text, message_html: ERB::Util.html_escape(text))
        else
          raise ArgumentError, "Unknown error kind #{kind.inspect}"
        end
      end

      # GitHub OAuth tokens do not expire (unless the App opts in, which morph.io's does not).
      sig { override.returns(T::Boolean) }
      def tokens_expire?
        false
      end

      sig { override.params(refresh_token: String).returns(Tokens) }
      def refresh_tokens(refresh_token)
        raise NotImplementedError, "GitHub tokens do not expire"
      end

      sig { override.params(identity: ForgeIdentity).returns(Forge::PersonClient) }
      def person_client(identity)
        PersonClient.new(Morph::Github.new(user_nickname: identity.login, user_access_token: T.must(identity.access_token)))
      end

      sig { params(owner: Owner).returns(String) }
      def login_of(owner)
        owner.github_identity&.login || T.must(owner.nickname)
      end

      # Morph::Github (Octokit as the signed-in user) in the forge-neutral shape.
      class PersonClient < Forge::PersonClient
        extend T::Sig

        sig { params(github: Morph::Github).void }
        def initialize(github)
          super()
          @github = github
        end

        sig { override.params(owner: Owner).returns(T::Array[Repository]) }
        def repositories(owner)
          @github.public_repos(T.must(owner.nickname)).map { |repo| translate(repo) }
        end

        sig { override.params(full_name: String).returns(T.nilable(Repository)) }
        def repository(full_name)
          translate(@github.repository(full_name))
        rescue Octokit::NotFound
          nil
        end

        sig { override.params(owner: Owner, name: String, description: T.nilable(String), private: T::Boolean).returns(Repository) }
        def create_repository(owner:, name:, description:, private:)
          @github.create_repository(owner_nickname: T.must(owner.nickname), name: name, description: description, private: private)
          T.must(repository("#{owner.nickname}/#{name}"))
        end

        sig { override.params(repository: Repository, files: T::Hash[String, String], message: String).void }
        def commit_files(repository, files, message)
          @github.add_commit_to_root(repository.full_name, files, message, branch: repository.default_branch || "main")
        end

        sig { override.params(repository: Repository, private: T::Boolean).void }
        def set_visibility(repository, private:)
          @github.update_privacy(repository.full_name, private)
        end

        sig { override.params(repository: Repository, url: String).void }
        def set_homepage(repository, url)
          @github.update_repo_homepage(repository.full_name, url)
        end

        sig { override.returns(Profile) }
        def profile
          profile_from(@github.user_from_github(@github.user_nickname), email: @github.primary_email)
        end

        sig { override.returns(T::Array[Profile]) }
        def organizations
          @github.organizations(@github.user_nickname).map { |o| profile_from(o) }
        end

        sig { override.params(login: String).returns(T.nilable(Profile)) }
        def organization(login)
          profile_from(@github.organization(login))
        rescue Octokit::NotFound, Octokit::Unauthorized
          nil
        end

        private

        sig { params(owner: Morph::Github::Owner, email: T.nilable(String)).returns(Profile) }
        def profile_from(owner, email: owner.email)
          Profile.new(uid: owner.id.to_s, login: owner.login, name: owner.name, email: email, avatar_url: owner.rels.avatar.href,
                      blog: owner.blog, company: owner.company, location: owner.location)
        end

        sig { params(repo: Morph::Github::Repo).returns(Repository) }
        def translate(repo)
          Repository.new(
            id: repo.id, name: repo.name, full_name: repo.full_name, description: repo.description,
            private: repo.private, default_branch: repo.default_branch,
            web_url: repo.rels.html.href, clone_url: repo.rels.git.href, owner_login: repo.owner.login
          )
        end
      end

      # Translates Morph::GithubAppInstallation's results into the forge-neutral shape.
      class RepositoryAccess < Forge::RepositoryAccess
        extend T::Sig

        sig { params(forge: Github, scraper: Scraper).void }
        def initialize(forge, scraper)
          super()
          @forge = forge
          @scraper = scraper
          @installation = T.let(Morph::GithubAppInstallation.new(T.must(T.must(scraper.owner).nickname)), Morph::GithubAppInstallation)
        end

        sig { override.returns(T.nilable(Error)) }
        def confirm_has_access
          translate(@installation.confirm_has_access_to(@scraper.name))
        end

        sig { override.returns([T::Boolean, T.nilable(Error)]) }
        def private_repository
          private, error = @installation.repository_private?(@scraper.name)
          [private, translate(error)]
        end

        sig { override.returns(T.nilable(Error)) }
        def synchronise_repo
          translate(@installation.synchronise_repo(@scraper.repo_path, @scraper.git_url_https))
        end

        sig { override.returns([T::Array[Collaborator], T.nilable(Error)]) }
        def collaborators
          collaborators, error = @installation.collaborators(@scraper.name)
          translated = collaborators.map do |c|
            Collaborator.new(login: c.login, permissions: Permissions.new(c.permissions.serialize.symbolize_keys))
          end
          [translated, translate(error)]
        end

        sig { override.returns([T.nilable(T::Array[String]), T.nilable(Error)]) }
        def contributor_logins
          logins, error = @installation.contributor_nicknames(@scraper.name)
          [logins, translate(error)]
        end

        private

        sig do
          params(error: T.nilable(T.any(Morph::GithubAppInstallation::NoAppInstallationForOwner, Morph::GithubAppInstallation::AppInstallationNoAccessToRepo,
                                        Morph::GithubAppInstallation::NoAccessToRepo, Morph::GithubAppInstallation::SynchroniseRepoError))).returns(T.nilable(Error))
        end
        def translate(error)
          case error
          when nil then nil
          when Morph::GithubAppInstallation::NoAppInstallationForOwner then @forge.error(:not_connected, @scraper)
          when Morph::GithubAppInstallation::AppInstallationNoAccessToRepo then @forge.error(:no_access_to_repo, @scraper)
          when Morph::GithubAppInstallation::NoAccessToRepo, Morph::GithubAppInstallation::SynchroniseRepoError then @forge.error(:sync_failed, @scraper)
          else T.absurd(error)
          end
        end
      end
    end
  end
end
