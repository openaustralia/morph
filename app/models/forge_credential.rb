# typed: strict
# frozen_string_literal: true

# A credential morph.io holds in its own right for reaching repositories on a
# forge, as opposed to a person's OAuth token (ForgeIdentity). Belongs to an
# Owner (a group access token, a group deploy token) or to one Scraper (a
# project deploy token). See ADR 0007 for how they are chosen between.
# == Schema Information
#
# Table name: forge_credentials
#
#  id             :bigint           not null, primary key
#  expires_at     :datetime
#  forge_key      :string(255)      default("gitlab"), not null
#  kind           :string(255)      not null
#  token          :string(255)      not null
#  username       :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  forge_token_id :string(255)
#  owner_id       :integer
#  scraper_id     :integer
#
# Indexes
#
#  index_forge_credentials_on_owner_id             (owner_id)
#  index_forge_credentials_on_owner_id_and_kind    (owner_id,kind)
#  index_forge_credentials_on_scraper_id           (scraper_id)
#  index_forge_credentials_on_scraper_id_and_kind  (scraper_id,kind)
#
# Foreign Keys
#
#  fk_rails_...  (owner_id => owners.id)
#  fk_rails_...  (scraper_id => scrapers.id)
#
class ForgeCredential < ApplicationRecord
  extend T::Sig

  KINDS = T.let(%w[group_access_token deploy_token].freeze, T::Array[String])

  belongs_to :owner, optional: true
  belongs_to :scraper, optional: true

  validates :kind, inclusion: { in: KINDS }
  validates :token, presence: true
  validate :belongs_to_exactly_one_of_owner_or_scraper

  scope :live, -> { where(expires_at: nil).or(where("expires_at > ?", Time.zone.now)) }
  scope :group_access_tokens, -> { where(kind: "group_access_token") }
  scope :deploy_tokens, -> { where(kind: "deploy_token") }

  # Can this credential call the API, or only clone?
  sig { returns(T::Boolean) }
  def api?
    kind == "group_access_token"
  end

  # The username git needs alongside the token. A deploy token comes with its
  # own; anything OAuth-shaped uses GitLab's fixed `oauth2`.
  sig { returns(String) }
  def git_username
    username.presence || "oauth2"
  end

  sig { returns(T::Boolean) }
  def expired?
    expires_at.present? && T.must(expires_at) <= Time.zone.now
  end

  private

  sig { void }
  def belongs_to_exactly_one_of_owner_or_scraper
    return if owner_id.present? ^ scraper_id.present?

    errors.add(:base, "must belong to an owner or a scraper, not both or neither")
  end
end
