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
    existing = ForgeIdentity.owner_for("github", uid)
    return T.cast(existing, Organization) if existing

    transaction do
      org = Organization.create!(nickname: login)
      org.forge_identities.create!(forge_key: "github", uid: uid, login: login)
      org
    end
  end

  sig { params(user: User).void }
  def refresh_info_from_github!(user)
    data = user.github.organization(T.must(nickname))
    update(
      nickname: data.login, name: data.name, blog: data.blog,
      company: data.company, location: data.location, email: data.email,
      gravatar_url: data.rels.avatar.href
    )
  rescue Octokit::Unauthorized, Octokit::NotFound
    false
  end
end
