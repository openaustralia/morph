# Using American spelling to match GitHub usage
class Organization < Owner
  # TODO: rename this to members
  has_and_belongs_to_many :users, join_table: :organizations_users

  def user?
    false
  end

  def organization?
    true
  end

  def self.find_or_create(uid, nickname)
    org = Organization.find_by(uid: uid)
    if org.nil?
      org = Organization.create(uid: uid, nickname: nickname)
    end
    org
  end

  def refresh_info_from_github!(octokit_client)
    data = octokit_client.organization(nickname)
    update_attributes(
      nickname: data.login, name: data.name, blog: data.blog,
      company: data.company, location: data.location, email: data.email,
      gravatar_url: data.rels[:avatar].href)
  end

  def organizations
    []
  end

  # All organizations that have scrapers
  def self.all_with_scrapers
    Organization.joins(:scrapers).group(:owner_id)
  end
end
