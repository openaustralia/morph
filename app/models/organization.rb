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
