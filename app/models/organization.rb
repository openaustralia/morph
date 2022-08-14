# typed: strict
# frozen_string_literal: true

# Using American spelling to match GitHub usage
class Organization < Owner
  extend T::Sig

  has_many :organizations_users, dependent: :destroy
  # TODO: rename this to members
  has_many :users, through: :organizations_users

  sig { returns(T::Boolean) }
  def user?
    false
  end

  sig { returns(T::Boolean) }
  def organization?
    true
  end

  # TODO: Use find_or_create_by instaead
  sig { params(uid: String, nickname: String).returns(Organization) }
  def self.find_or_create(uid, nickname)
    Organization.find_by(uid: uid) || Organization.create(uid: uid, nickname: nickname)
  end

  sig { params(octokit_client: Octokit::Client).void }
  def refresh_info_from_github!(octokit_client)
    data = octokit_client.organization(nickname)
    update(
      nickname: data.login, name: data.name, blog: data.blog,
      company: data.company, location: data.location, email: data.email,
      gravatar_url: data.rels[:avatar].href
    )
  rescue Octokit::Unauthorized, Octokit::NotFound
    false
  end

  sig { returns(T::Array[Organization]) }
  # TODO: Really shouldn't have to define this as it doesn't make any sense intuitively
  # I think it's being done so that things work with the current cancan setup?
  def organizations
    []
  end

  # All organizations that have scrapers
  sig { returns(Organization::PrivateRelation) }
  def self.all_with_scrapers
    Organization.joins(:scrapers).group(:owner_id)
  end
end
