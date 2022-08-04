# typed: false
# frozen_string_literal: true

# Using American spelling to match GitHub usage
class Organization < Owner
  has_many :organizations_users, dependent: :destroy
  # TODO: rename this to members
  has_many :users, through: :organizations_users

  def user?
    false
  end

  def organization?
    true
  end

  def self.find_or_create(uid, nickname)
    Organization.find_by(uid: uid) || Organization.create(uid: uid, nickname: nickname)
  end

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

  def organizations
    []
  end

  # All organizations that have scrapers
  def self.all_with_scrapers
    Organization.joins(:scrapers).group(:owner_id)
  end
end
