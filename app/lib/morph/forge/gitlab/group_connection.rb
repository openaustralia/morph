# typed: strict
# frozen_string_literal: true

module Morph
  module Forge
    class Gitlab < Base
      # Connects an Organization's GitLab group to morph.io by creating the most
      # durable credential the group's plan and the connecting member's role
      # allow, found by trying rather than by reading the plan (ADR 0007).
      class GroupConnection
        extend T::Sig

        TOKEN_NAME = "morph.io"
        # gitlab.com caps access tokens at 400 days; a year leaves room to rotate.
        ACCESS_TOKEN_LIFETIME = T.let(364.days, ActiveSupport::Duration)

        sig { params(organization: Organization, member: User).void }
        def initialize(organization, member)
          @organization = organization
          @member = member
        end

        # The tier reached. Whatever is created replaces an earlier credential
        # of the same kind, so reconnecting rotates rather than accumulates.
        sig { returns(Symbol) }
        def connect!
          api = client
          return :none if api.nil?

          group_id = T.must(@organization.forge_identity("gitlab")).uid.to_i

          begin
            token = api.create_group_access_token(group_id, name: TOKEN_NAME, expires_at: ACCESS_TOKEN_LIFETIME.from_now.to_date)
            store!("group_access_token", token)
            return :group_access_token
          rescue Morph::GitlabClient::Forbidden, Morph::GitlabClient::Error => e
            Rails.logger.info "Group access token not available for #{@organization.nickname}: #{e.message}"
          end

          begin
            token = api.create_group_deploy_token(group_id, name: TOKEN_NAME)
            store!("deploy_token", token)
            return :deploy_token
          rescue Morph::GitlabClient::Forbidden, Morph::GitlabClient::Error => e
            Rails.logger.info "Group deploy token not available for #{@organization.nickname}: #{e.message}"
          end

          :oauth
        end

        sig { returns(Symbol) }
        def tier
          credentials = @organization.forge_credentials
          if credentials.group_access_tokens.live.exists?
            :group_access_token
          elsif credentials.deploy_tokens.live.exists?
            :deploy_token
          elsif member_identities.any?
            :oauth
          else
            :none
          end
        end

        private

        sig { params(kind: String, token: Morph::GitlabClient::Token).void }
        def store!(kind, token)
          @organization.transaction do
            @organization.forge_credentials.where(kind: kind).destroy_all
            @organization.forge_credentials.create!(
              kind: kind, forge_key: "gitlab", token: token.token, username: token.username,
              expires_at: token.expires_at&.end_of_day, forge_token_id: token.id.to_s
            )
          end
        end

        sig { returns(T.nilable(Morph::GitlabClient)) }
        def client
          identity = @member.forge_identity("gitlab")
          return nil if identity.nil? || identity.access_token.blank?

          Morph::GitlabClient.new(access_token: T.must(identity.fresh_access_token))
        end

        sig { returns(T::Array[ForgeIdentity]) }
        def member_identities
          @organization.users.filter_map { |user| user.forge_identity("gitlab") }.select { |identity| identity.access_token.present? }
        end
      end
    end
  end
end
