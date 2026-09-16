# typed: strict
# frozen_string_literal: true

# One Owner's account on one Forge (GitHub or GitLab). An Owner holds at most
# one per Forge, and a forge account belongs to at most one Owner (ADR 0008).
# == Schema Information
#
# Table name: forge_identities
#
#  id               :bigint           not null, primary key
#  access_token     :string(255)
#  forge_key        :string(255)      not null
#  login            :string(255)      not null
#  refresh_token    :string(255)
#  scopes           :string(255)
#  token_expires_at :datetime
#  uid              :string(255)      not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  owner_id         :integer          not null
#
# Indexes
#
#  index_forge_identities_on_forge_key_and_uid       (forge_key,uid) UNIQUE
#  index_forge_identities_on_owner_id                (owner_id)
#  index_forge_identities_on_owner_id_and_forge_key  (owner_id,forge_key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (owner_id => owners.id)
#
class ForgeIdentity < ApplicationRecord
  extend T::Sig

  FORGES = T.let(%w[github gitlab].freeze, T::Array[String])

  belongs_to :owner

  validates :forge_key, inclusion: { in: FORGES }
  validates :uid, presence: true, uniqueness: { scope: :forge_key }
  validates :login, presence: true
  validates :owner_id, uniqueness: { scope: :forge_key }

  # How long before expiry a token is treated as already expired, so a Run
  # that starts with a token about to lapse does not fail half way through.
  REFRESH_MARGIN = T.let(5.minutes, ActiveSupport::Duration)

  sig { params(forge_key: String, uid: String).returns(T.nilable(Owner)) }
  def self.owner_for(forge_key, uid)
    find_by(forge_key: forge_key, uid: uid)&.owner
  end

  sig { returns(Morph::Forge::Base) }
  def forge
    Morph::Forge.for(forge_key)
  end

  sig { params(tokens: Morph::Forge::Tokens).void }
  def store_tokens!(tokens)
    update!(access_token: tokens.access_token, refresh_token: tokens.refresh_token, token_expires_at: tokens.expires_at)
  end

  # An access token good for at least REFRESH_MARGIN, refreshing it first if
  # need be. The refresh happens under a row lock because the forge
  # invalidates the old refresh token on use: two workers refreshing at once
  # would leave the loser holding a dead token (ADR 0007). Re-checked after
  # taking the lock, since the other worker may already have done the work.
  sig { returns(T.nilable(String)) }
  def fresh_access_token
    return access_token unless expiring_soon?

    with_lock do
      store_tokens!(forge.refresh_tokens(T.must(refresh_token))) if expiring_soon?
    end
    access_token
  end

  sig { returns(T::Boolean) }
  def expiring_soon?
    expires_at = token_expires_at
    !expires_at.nil? && expires_at <= REFRESH_MARGIN.from_now
  end
end
