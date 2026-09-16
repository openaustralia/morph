# typed: false
# frozen_string_literal: true

require "spec_helper"

# Connecting an Organization's GitLab group to morph.io: creating the most
# durable credential the group's plan allows (ADR 0007).
describe Morph::Forge::Gitlab::GroupConnection do
  let(:org) do
    o = Organization.create!(nickname: "acme")
    o.forge_identities.create!(forge_key: "gitlab", uid: "9", login: "acme")
    o
  end
  let(:member) do
    u = create(:user, :forgeless, nickname: "alice")
    u.forge_identities.create!(forge_key: "gitlab", uid: "1", login: "alice", access_token: "tok", token_expires_at: 1.hour.from_now)
    org.users << u
    u
  end
  let(:client) { instance_double(Morph::GitlabClient) }
  let(:connection) { described_class.new(org, member) }

  before do
    allow(Morph::GitlabClient).to receive(:new).with(access_token: "tok").and_return(client)
    allow(client).to receive_messages(groups: [Morph::GitlabClient::Group.new(id: 9, path: "acme", name: "Acme", web_url: "w", avatar_url: nil, description: nil)], members: [])
  end

  describe "#connect!" do
    it "creates a group access token when the plan allows, stored on the Organization with its expiry" do
      allow(client).to receive(:create_group_access_token).with(9, name: "morph.io", expires_at: an_instance_of(Date))
                                                          .and_return(Morph::GitlabClient::Token.new(id: 1, token: "glpat", username: nil, expires_at: Time.zone.today + 364))

      expect(connection.connect!).to eq(:group_access_token)

      credential = org.forge_credentials.group_access_tokens.first
      expect(credential.token).to eq("glpat")
      expect(credential.expires_at.to_date).to eq(Time.zone.today + 364)
    end

    it "falls through to a group deploy token when access tokens are not on this plan" do
      allow(client).to receive(:create_group_access_token).and_raise(Morph::GitlabClient::Forbidden)
      allow(client).to receive(:create_group_deploy_token).with(9, name: "morph.io")
                                                          .and_return(Morph::GitlabClient::Token.new(id: 2, token: "gdt", username: "gitlab+deploy-token-2", expires_at: nil))

      expect(connection.connect!).to eq(:deploy_token)

      credential = org.forge_credentials.deploy_tokens.first
      expect(credential).to have_attributes(token: "gdt", username: "gitlab+deploy-token-2")
    end

    it "settles for the member's OAuth token when neither can be created" do
      allow(client).to receive(:create_group_access_token).and_raise(Morph::GitlabClient::Forbidden)
      allow(client).to receive(:create_group_deploy_token).and_raise(Morph::GitlabClient::Forbidden)

      expect(connection.connect!).to eq(:oauth)
      expect(org.forge_credentials).to be_empty
    end

    it "replaces an earlier credential of the same kind rather than piling up" do
      org.forge_credentials.create!(kind: "group_access_token", token: "old", expires_at: 1.month.from_now)
      allow(client).to receive(:create_group_access_token).and_return(Morph::GitlabClient::Token.new(id: 3, token: "new", username: nil, expires_at: Time.zone.today + 364))

      connection.connect!

      expect(org.forge_credentials.group_access_tokens.pluck(:token)).to eq(["new"])
    end
  end

  describe "#tier" do
    it "reports which tier is in force" do
      expect(connection.tier).to eq(:oauth)

      org.forge_credentials.create!(kind: "deploy_token", token: "gdt", username: "u")
      expect(connection.tier).to eq(:deploy_token)

      org.forge_credentials.create!(kind: "group_access_token", token: "glpat", expires_at: 1.year.from_now)
      expect(connection.tier).to eq(:group_access_token)
    end

    it "is none when no member has a working GitLab sign-in" do
      member.forge_identity("gitlab").update!(access_token: nil)

      expect(connection.tier).to eq(:none)
    end
  end
end
