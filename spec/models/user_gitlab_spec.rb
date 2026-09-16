# typed: false
# frozen_string_literal: true

require "spec_helper"

# A GitLab user's top-level groups become Organizations, and their profile
# comes from GitLab, the way GitHub organisations and profiles do.
describe User do
  let(:user) do
    u = create(:user, :forgeless, nickname: "alice")
    u.forge_identities.create!(forge_key: "gitlab", uid: "1", login: "alice", access_token: "tok", token_expires_at: 1.hour.from_now)
    u
  end
  let(:client) { instance_double(Morph::GitlabClient) }

  before { allow(Morph::GitlabClient).to receive(:new).with(access_token: "tok").and_return(client) }

  describe "#refresh_organizations!" do
    let(:acme) { Morph::GitlabClient::Group.new(id: 9, path: "acme", name: "Acme Inc", web_url: "https://gitlab.com/groups/acme", avatar_url: "https://gitlab.com/a.png", description: "d") }

    before do
      allow(client).to receive(:groups).and_return([acme])
      allow(client).to receive(:group).with(9).and_return(acme)
    end

    it "creates an Organization for each top-level group, with a GitLab identity, and joins the user to it" do
      user.refresh_organizations!

      org = ForgeIdentity.owner_for("gitlab", "9")
      expect(org).to be_an(Organization)
      expect(org).to have_attributes(nickname: "acme", name: "Acme Inc")
      expect(org.gravatar_url).to start_with("https://gitlab.com/a.png")
      expect(user.organizations).to include(org)
      expect(user.watching?(org)).to be true
    end

    it "recognises a group already known as an Organization by its GitLab id" do
      org = Organization.create!(nickname: "acme-old")
      org.forge_identities.create!(forge_key: "gitlab", uid: "9", login: "acme")

      user.refresh_organizations!

      expect(user.organizations).to eq([org])
    end

    it "drops membership of groups the user has left, on this forge only" do
      github_org = create(:organization, nickname: "gh-org")
      user.organizations << github_org
      stale = Organization.create!(nickname: "left")
      stale.forge_identities.create!(forge_key: "gitlab", uid: "8", login: "left")
      user.organizations << stale

      user.refresh_organizations!

      expect(user.organizations.map(&:nickname)).to contain_exactly("gh-org", "acme")
    end

    it "gives a group whose path is already someone's nickname a suffixed nickname" do
      create(:user, nickname: "acme")

      user.refresh_organizations!

      expect(ForgeIdentity.owner_for("gitlab", "9").nickname).to eq("acme-gitlab")
    end
  end

  describe "#refresh_info_from_forge!" do
    it "fills in the profile from GitLab" do
      profile = Morph::GitlabClient::User.new(id: 1, username: "alice", name: "Alice", email: "alice@example.com", avatar_url: "https://gitlab.com/u.png",
                                              web_url: "w", website_url: "https://alice.example", organization: "Acme", location: "Sydney")
      allow(client).to receive(:current_user).and_return(profile)

      user.refresh_info_from_forge!(Morph::Forge.for("gitlab"))

      expect(user.reload).to have_attributes(name: "Alice", email: "alice@example.com", blog: "https://alice.example", company: "Acme", location: "Sydney")
    end
  end
end
