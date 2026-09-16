# typed: strict
# frozen_string_literal: true

# Using American spelling to match GitHub usage
#
# == Schema Information
#
# Table name: owners
#
#  id                     :integer          not null, primary key
#  admin                  :boolean          default(FALSE), not null
#  alerted_at             :datetime
#  api_key                :string(255)
#  blog                   :string(255)
#  company                :string(255)
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string(255)
#  email                  :string(255)
#  feature_switches       :string(255)
#  gravatar_url           :string(255)
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string(255)
#  location               :string(255)
#  name                   :string(255)
#  nickname               :string(255)
#  remember_created_at    :datetime
#  remember_token         :string(255)
#  sign_in_count          :integer          default(0), not null
#  suspended              :boolean          default(FALSE), not null
#  type                   :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  stripe_customer_id     :string(255)
#  stripe_plan_id         :string(255)
#  stripe_subscription_id :string(255)
#
# Indexes
#
#  index_owners_on_api_key   (api_key)
#  index_owners_on_nickname  (nickname) UNIQUE
#
class Organization < Owner
  extend T::Sig

  has_many :organizations_users, dependent: :destroy
  # TODO: rename this to members
  has_many :users, through: :organizations_users

  sig { override.returns(T::Boolean) }
  def user?
    false
  end

  sig { override.returns(T::Boolean) }
  def organization?
    true
  end

  # Organizations are recognised by their GitHub id, because a GitHub
  # organisation can be renamed and its login is then someone else's to take.
  sig { params(uid: String, login: String).returns(Organization) }
  def self.find_or_create_from_github!(uid:, login:)
    profile = Morph::Forge::Profile.new(uid: uid, login: login, name: nil, email: nil, avatar_url: nil, blog: nil, company: nil, location: nil)
    find_or_create_from_forge!(Morph::Forge.for("github"), profile)
  end

  # Recognised by its id on the forge, since a group can be renamed and its
  # path is then someone else's to take. A new one gets the path as its
  # nickname unless another Owner already answers to it (ADR 0008).
  sig { params(forge: Morph::Forge::Base, profile: Morph::Forge::Profile).returns(Organization) }
  def self.find_or_create_from_forge!(forge, profile)
    existing = ForgeIdentity.owner_for(forge.key, profile.uid)
    return T.cast(existing, Organization) if existing

    transaction do
      org = Organization.create!(nickname: Owner.available_nickname(profile.login, forge.key))
      org.forge_identities.create!(forge_key: forge.key, uid: profile.uid, login: profile.login)
      org
    end
  end

  sig { params(profile: Morph::Forge::Profile).void }
  def refresh_info_from_profile!(profile)
    update(name: profile.name, blog: profile.blog, company: profile.company, location: profile.location,
           email: profile.email, gravatar_url: profile.avatar_url)
  end

  # Refreshes from whichever forge the organisation is on, through a member's
  # account there. Quietly does nothing if no member can reach it.
  sig { params(user: User).void }
  def refresh_info_from_github!(user)
    forge_identities.each do |org_identity|
      forge = org_identity.forge
      member_identity = user.forge_identity(forge.key)
      next if member_identity.nil? || member_identity.access_token.blank?

      profile = forge.person_client(member_identity).organization(org_identity.login)
      refresh_info_from_profile!(profile) if profile
    end
  rescue Octokit::Unauthorized, Octokit::NotFound, Morph::GitlabClient::Unauthorized
    false
  end
end
