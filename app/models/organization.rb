# typed: strict
# frozen_string_literal: true

# == Schema Information
#
# Table name: owners
#
#  id                     :integer          not null, primary key
#  access_token           :string(255)
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
#  provider               :string(255)
#  remember_created_at    :datetime
#  remember_token         :string(255)
#  sign_in_count          :integer          default(0), not null
#  suspended              :boolean          default(FALSE), not null
#  type                   :string(255)
#  uid                    :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  stripe_customer_id     :string(255)
#  stripe_plan_id         :string(255)
#  stripe_subscription_id :string(255)
#
# Indexes
#
#  index_owners_on_api_key   (api_key)
#  index_owners_on_nickname  (nickname)
#

# Using American spelling to match GitHub usage
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

  # All organizations that have scrapers
  sig { returns(ActiveRecord::Relation) }
  def self.all_with_scrapers
    Organization.joins(:scrapers).group(:owner_id)
  end
end
