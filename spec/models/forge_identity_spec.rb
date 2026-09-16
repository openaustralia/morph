# typed: false
# frozen_string_literal: true

require "spec_helper"

# An Owner is known to morph.io through its Forge identities (see ADR 0008).
# These cover the seams that read and write them: signing in with GitHub,
# and recognising an Organization by its GitHub id.
# == Schema Information
#
# Table name: forge_identities
#
#  id               :bigint           not null, primary key
#  access_token     :string(255)
#  forge_key        :string(255)      not null
#  login            :string(255)      not null
#  refresh_token    :string(255)
#  scopes           :string(255)
#  token_expires_at :datetime
#  uid              :string(255)      not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  owner_id         :integer          not null
#
# Indexes
#
#  index_forge_identities_on_forge_key_and_uid       (forge_key,uid) UNIQUE
#  index_forge_identities_on_owner_id                (owner_id)
#  index_forge_identities_on_owner_id_and_forge_key  (owner_id,forge_key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (owner_id => owners.id)
#
describe ForgeIdentity do
  def github_auth(uid:, nickname:, token: "gh_token")
    OmniAuth::AuthHash.new(
      provider: "github", uid: uid,
      info: OmniAuth::AuthHash::InfoHash.new(nickname: nickname),
      credentials: OmniAuth::AuthHash.new(token: token)
    )
  end

  before do
    # Profile refresh talks to GitHub, which is not the seam under test here.
    allow_any_instance_of(User).to receive(:refresh_info_from_github!) # rubocop:disable RSpec/AnyInstance
    allow(RefreshUserOrganizationsWorker).to receive(:perform_async)
  end

  describe "User.find_or_create_from_oauth with GitHub" do
    it "creates a User with a GitHub identity holding the uid, login and token" do
      user = User.find_or_create_from_oauth(Morph::Forge.for("github"), github_auth(uid: "42", nickname: "alice", token: "tok"))

      identity = user.forge_identity("github")
      expect(user.nickname).to eq("alice")
      expect(identity).to have_attributes(uid: "42", login: "alice", access_token: "tok")
    end

    it "finds an existing User by GitHub uid even after they renamed themselves on GitHub" do
      existing = create(:user, nickname: "alice")
      existing.forge_identities.create!(forge_key: "github", uid: "42", login: "alice", access_token: "old")

      user = User.find_or_create_from_oauth(Morph::Forge.for("github"), github_auth(uid: "42", nickname: "alice-renamed", token: "new"))

      expect(user).to eq(existing)
      expect(user.nickname).to eq("alice-renamed")
      expect(user.forge_identity("github")).to have_attributes(login: "alice-renamed", access_token: "new")
    end

    it "does not confuse two forges that happen to issue the same uid" do
      other = create(:user, nickname: "bob")
      other.forge_identities.create!(forge_key: "gitlab", uid: "42", login: "bob")

      user = User.find_or_create_from_oauth(Morph::Forge.for("github"), github_auth(uid: "42", nickname: "alice"))

      expect(user).not_to eq(other)
    end
  end

  describe "User#github" do
    it "authenticates as the user's GitHub identity" do
      user = create(:user)
      user.forge_identities.create!(forge_key: "github", uid: "1", login: user.nickname, access_token: "tok")

      allow(Morph::Github).to receive(:new).and_call_original
      user.github

      expect(Morph::Github).to have_received(:new).with(user_nickname: user.nickname, user_access_token: "tok")
    end
  end

  describe "Organization.find_or_create_from_github!" do
    it "recognises an Organization by its GitHub id, not its current login" do
      org = Organization.create!(nickname: "old-name")
      org.forge_identities.create!(forge_key: "github", uid: "99", login: "old-name")

      found = Organization.find_or_create_from_github!(uid: "99", login: "new-name")

      expect(found).to eq(org)
    end

    it "creates the Organization and its identity when the GitHub id is new" do
      org = Organization.find_or_create_from_github!(uid: "99", login: "acme")

      expect(org.nickname).to eq("acme")
      expect(org.forge_identity("github")).to have_attributes(uid: "99", login: "acme")
    end
  end

  describe "uniqueness" do
    it "refuses a second identity on the same forge for one Owner" do
      user = create(:user)
      user.forge_identities.create!(forge_key: "github", uid: "1", login: "a")

      expect { user.forge_identities.create!(forge_key: "github", uid: "2", login: "b") }
        .to raise_error(ActiveRecord::RecordInvalid)
    end

    it "refuses the same forge account being attached to two Owners" do
      create(:user).forge_identities.create!(forge_key: "github", uid: "1", login: "a")

      expect { create(:user).forge_identities.create!(forge_key: "github", uid: "1", login: "a") }
        .to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
