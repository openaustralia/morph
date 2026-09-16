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

  sig { params(forge_key: String, uid: String).returns(T.nilable(Owner)) }
  def self.owner_for(forge_key, uid)
    find_by(forge_key: forge_key, uid: uid)&.owner
  end
end
