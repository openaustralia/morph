# typed: strict
# frozen_string_literal: true

module Morph
  module Forge
    class Gitlab < Base
      # Reaches one scraper's GitLab project with the best credential to hand
      # (ADR 0007). For the API: the Organization's group access token, else
      # any collaborator's OAuth token that still works. For cloning: a project
      # deploy token, else a group deploy token, else whichever API credential
      # was found.
      class RepositoryAccess < Forge::RepositoryAccess
        extend T::Sig

        sig { params(forge: Gitlab, scraper: Scraper).void }
        def initialize(forge, scraper)
          super()
          @forge = forge
          @scraper = scraper
          @api_token = T.let(nil, T.nilable(String))
          @api_client = T.let(nil, T.nilable(Morph::GitlabClient))
          @api_resolved = T.let(false, T::Boolean)
          @project = T.let(nil, T.nilable(Morph::GitlabClient::Project))
        end

        sig { override.returns(T.nilable(Error)) }
        def confirm_has_access
          project, error = fetch_project
          return error if error
          return @forge.error(:no_access_to_repo, @scraper) if project.nil?

          nil
        end

        sig { override.returns([T::Boolean, T.nilable(Error)]) }
        def private_repository
          project, error = fetch_project
          return [false, error] if error
          return [false, @forge.error(:no_access_to_repo, @scraper)] if project.nil?

          [project.private, nil]
        end

        sig { override.returns(T.nilable(Error)) }
        def synchronise_repo
          credential = clone_credential
          return @forge.error(:not_connected, @scraper) if credential.nil?

          username, password = credential
          Morph::GitSync.synchronise(@scraper.repo_path, @scraper.git_url_https, username: username, password: password)
          nil
        rescue Morph::GitSync::Failed
          @forge.error(:sync_failed, @scraper)
        end

        sig { override.returns([T::Array[Collaborator], T.nilable(Error)]) }
        def collaborators
          project, error = fetch_project
          return [[], error] if error
          return [[], @forge.error(:no_access_to_repo, @scraper)] if project.nil?

          members = T.must(client).members(project.id).map do |member|
            Collaborator.new(login: member.username, permissions: Gitlab.permissions_for(member.access_level))
          end
          [members, nil]
        end

        # GitLab's contributors endpoint gives names and emails, not usernames,
        # and looking users up by email is admin-only on gitlab.com.
        sig { override.returns([T.nilable(T::Array[String]), T.nilable(Error)]) }
        def contributor_logins
          [nil, nil]
        end

        # True when the repository can be cloned but nobody can reach the API:
        # a Run can go ahead on last-known permissions, flagged for attention.
        sig { override.returns(T::Boolean) }
        def api_credential_missing?
          !clone_credential.nil? && client.nil?
        end

        # Which tier of ADR 0007 is in force, for the Organization page.
        sig { returns(Symbol) }
        def tier
          if owner_credentials.group_access_tokens.live.exists?
            :group_access_token
          elsif clone_only_credential
            :deploy_token
          elsif client
            :oauth
          else
            :none
          end
        end

        private

        sig { returns([T.nilable(Morph::GitlabClient::Project), T.nilable(Error)]) }
        def fetch_project
          api = client
          return [nil, @forge.error(:not_connected, @scraper)] if api.nil?

          # working_client fetched it while proving the token
          [@project, nil]
        end

        # An API client, from the first credential that GitLab still accepts.
        sig { returns(T.nilable(Morph::GitlabClient)) }
        def client
          resolve_api unless @api_resolved
          @api_client
        end

        sig { returns(T.nilable(String)) }
        def api_token
          resolve_api unless @api_resolved
          @api_token
        end

        # Settles on the first candidate token GitLab still accepts. Any call
        # proves a token; fetching the project is one we need anyway.
        sig { void }
        def resolve_api
          @api_resolved = true
          api_token_candidates.each do |token|
            candidate = Morph::GitlabClient.new(access_token: token)
            begin
              @project = candidate.project(T.must(@scraper.forge_repo_id))
            rescue Morph::GitlabClient::Unauthorized, Morph::GitlabClient::Forbidden
              next
            end
            @api_token = token
            @api_client = candidate
            break
          end
        end

        sig { returns(T::Array[String]) }
        def api_token_candidates
          group_tokens = owner_credentials.group_access_tokens.live.pluck(:token)
          oauth_tokens = collaborator_identities.filter_map(&:fresh_access_token)
          group_tokens + oauth_tokens
        end

        # GitLab identities of everyone with pull on this scraper, the owner
        # (if a person) first since they most likely added it.
        sig { returns(T::Array[ForgeIdentity]) }
        def collaborator_identities
          owner = T.must(@scraper.owner)
          people = [owner.is_a?(User) ? owner : nil].compact + @scraper.collaborations.where(pull: true).includes(:owner).map(&:owner)
          people.uniq.filter_map { |person| person.forge_identity("gitlab") }.select { |identity| identity.access_token.present? }
        end

        sig { returns(T.nilable([String, String])) }
        def clone_credential
          if (credential = clone_only_credential)
            [credential.git_username, credential.token]
          elsif (token = api_token)
            ["oauth2", token]
          end
        end

        sig { returns(T.nilable(ForgeCredential)) }
        def clone_only_credential
          @scraper.forge_credentials.deploy_tokens.live.first || owner_credentials.deploy_tokens.live.first
        end

        sig { returns(ActiveRecord::Relation) }
        def owner_credentials
          T.must(@scraper.owner).forge_credentials
        end
      end
    end
  end
end
