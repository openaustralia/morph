# typed: strict
# frozen_string_literal: true

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

  # TODO: Use find_or_create_by instaead
  sig { params(uid: String, nickname: String).returns(Organization) }
  def self.find_or_create(uid, nickname)
    Organization.find_by(uid: uid) || Organization.create(uid: uid, nickname: nickname)
  end

  sig { params(user: User).void }
  def refresh_info_from_github!(user)
    data = user.octokit_client.organization(nickname)
    update(
      nickname: data.login, name: data.name, blog: data.blog,
      company: data.company, location: data.location, email: data.email,
      gravatar_url: data.rels[:avatar].href
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
