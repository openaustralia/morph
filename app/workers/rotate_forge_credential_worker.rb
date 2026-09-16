# typed: strict
# frozen_string_literal: true

# Group access tokens on gitlab.com live at most 400 days, so morph.io rotates
# its own ahead of expiry (ADR 0007). Rotation invalidates the old token, and
# the new one is stored in the same row so anything holding the row's id keeps
# working.
class RotateForgeCredentialWorker
  extend T::Sig

  include Sidekiq::Worker
  sidekiq_options backtrace: true

  ROTATE_AHEAD = T.let(30.days, ActiveSupport::Duration)

  sig { params(id: Integer).void }
  def perform(id)
    credential = ForgeCredential.find(id)
    return unless credential.api?

    group_id = T.must(T.must(credential.owner).forge_identity("gitlab")).uid.to_i
    rotated = Morph::GitlabClient.new(access_token: credential.token)
                                 .rotate_group_access_token(group_id, T.must(credential.forge_token_id).to_i,
                                                            expires_at: Morph::Forge::Gitlab::GroupConnection::ACCESS_TOKEN_LIFETIME.from_now.to_date)
    credential.update!(token: rotated.token, expires_at: rotated.expires_at&.end_of_day, forge_token_id: rotated.id.to_s)
  end
end
