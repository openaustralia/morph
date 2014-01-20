# Using American spelling to match GitHub usage
class Organization < Owner
  def self.find_or_create(uid, nickname)
    org = Organization.find_by(uid: uid)
    if org.nil?
      # Get more information for that organisation
      data = Octokit.organization(nickname)
      org = Organization.create(uid: uid, nickname: nickname, name: data.name, blog: data.blog, company: data.company,
        email: data.email, gravatar_url: data.rels[:avatar].href)
    end
    org
  end
end
