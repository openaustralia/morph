# typed: false
# frozen_string_literal: true

require "spec_helper"

# Reaching a GitLab repository with whatever credential the owner's plan and
# the connecting person's role allowed (ADR 0007). The tiers, best first:
# a group access token on the Organization; a deploy token for cloning plus a
# collaborator's OAuth token for the API; a collaborator's OAuth token alone.
describe Morph::Forge::Gitlab::RepositoryAccess do
  let(:forge) { Morph::Forge::Gitlab.new }
  let(:org) do
    o = Organization.create!(nickname: "acme")
    o.forge_identities.create!(forge_key: "gitlab", uid: "9", login: "acme")
    o
  end
  let(:scraper) do
    create(:scraper, owner: org, name: "planning", forge_key: "gitlab", forge_repo_id: 7,
                     repo_url: "https://gitlab.com/acme/planning", git_url: "https://gitlab.com/acme/planning.git")
  end
  let(:client) { instance_double(Morph::GitlabClient) }
  let(:access) { described_class.new(forge, scraper) }

  def project(**overrides)
    Morph::GitlabClient::Project.new(id: 7, path: "planning", full_path: "acme/planning", description: nil, private: false, default_branch: "main",
                                     web_url: "https://gitlab.com/acme/planning", http_url_to_repo: "https://gitlab.com/acme/planning.git",
                                     namespace: Morph::GitlabClient::Namespace.new(id: 9, path: "acme", group: true), **overrides)
  end

  def alice_with_token(token = "alice-tok", pull: true)
    alice = create(:user, nickname: "alice")
    alice.forge_identities.create!(forge_key: "gitlab", uid: "1", login: "alice", access_token: token, token_expires_at: 1.hour.from_now)
    scraper.collaborations.create!(owner: alice, pull: pull, triage: false, push: false, maintain: false, admin: false)
    alice
  end

  describe "choosing an API credential" do
    it "prefers the Organization's group access token" do
      org.forge_credentials.create!(kind: "group_access_token", token: "glpat-group", expires_at: 1.year.from_now)
      alice_with_token
      allow(Morph::GitlabClient).to receive(:new).with(access_token: "glpat-group").and_return(client)
      allow(client).to receive(:project).with(7).and_return(project)

      expect(access.confirm_has_access).to be_nil
    end

    it "falls back to a collaborator's OAuth token" do
      alice_with_token("alice-tok")
      allow(Morph::GitlabClient).to receive(:new).with(access_token: "alice-tok").and_return(client)
      allow(client).to receive(:project).with(7).and_return(project)

      expect(access.confirm_has_access).to be_nil
    end

    it "ignores a group access token that has expired" do
      org.forge_credentials.create!(kind: "group_access_token", token: "glpat-old", expires_at: 1.day.ago)
      alice_with_token("alice-tok")
      allow(Morph::GitlabClient).to receive(:new).with(access_token: "alice-tok").and_return(client)
      allow(client).to receive(:project).with(7).and_return(project)

      expect(access.confirm_has_access).to be_nil
    end

    it "tries the next collaborator when one's token no longer works" do
      alice_with_token("alice-tok")
      bob = create(:user, nickname: "bob")
      bob.forge_identities.create!(forge_key: "gitlab", uid: "2", login: "bob", access_token: "bob-tok", token_expires_at: 1.hour.from_now)
      scraper.collaborations.create!(owner: bob, pull: true, triage: false, push: false, maintain: false, admin: false)
      dead = instance_double(Morph::GitlabClient)
      allow(Morph::GitlabClient).to receive(:new).with(access_token: "alice-tok").and_return(dead)
      allow(dead).to receive(:project).and_raise(Morph::GitlabClient::Unauthorized)
      allow(Morph::GitlabClient).to receive(:new).with(access_token: "bob-tok").and_return(client)
      allow(client).to receive(:project).with(7).and_return(project)

      expect(access.confirm_has_access).to be_nil
    end

    it "reports not connected when nobody has a working token" do
      error = access.confirm_has_access

      expect(error.kind).to eq(:not_connected)
      expect(error.message).to include("sign in with GitLab")
    end

    it "reports no access when the project cannot be seen with any token" do
      alice_with_token
      allow(Morph::GitlabClient).to receive(:new).and_return(client)
      allow(client).to receive(:project).with(7).and_return(nil)

      expect(access.confirm_has_access.kind).to eq(:no_access_to_repo)
    end
  end

  describe "#private_repository" do
    it "reads visibility from the project" do
      alice_with_token
      allow(Morph::GitlabClient).to receive(:new).and_return(client)
      allow(client).to receive(:project).with(7).and_return(project(private: true))

      expect(access.private_repository).to eq([true, nil])
    end
  end

  describe "#collaborators" do
    it "maps GitLab roles onto the five permissions morph.io stores" do
      alice_with_token
      allow(Morph::GitlabClient).to receive(:new).and_return(client)
      allow(client).to receive(:project).with(7).and_return(project)
      allow(client).to receive(:members).with(7).and_return([
                                                              Morph::GitlabClient::Member.new(id: 1, username: "guest", access_level: 10),
                                                              Morph::GitlabClient::Member.new(id: 2, username: "reporter", access_level: 20),
                                                              Morph::GitlabClient::Member.new(id: 3, username: "dev", access_level: 30),
                                                              Morph::GitlabClient::Member.new(id: 4, username: "maint", access_level: 40),
                                                              Morph::GitlabClient::Member.new(id: 5, username: "owner", access_level: 50)
                                                            ])

      collaborators, error = access.collaborators

      expect(error).to be_nil
      by_login = collaborators.to_h { |c| [c.login, c.permissions.serialize.symbolize_keys] }
      expect(by_login["guest"]).to eq(pull: false, triage: false, push: false, maintain: false, admin: false)
      expect(by_login["reporter"]).to eq(pull: true, triage: false, push: false, maintain: false, admin: false)
      expect(by_login["dev"]).to eq(pull: true, triage: true, push: true, maintain: false, admin: false)
      # Maintainers can change visibility and delete on GitLab, which is what admin gates here
      expect(by_login["maint"]).to eq(pull: true, triage: true, push: true, maintain: true, admin: true)
      expect(by_login["owner"]).to eq(pull: true, triage: true, push: true, maintain: true, admin: true)
    end
  end

  it "cannot say who the contributors are" do
    alice_with_token
    allow(Morph::GitlabClient).to receive(:new).and_return(client)
    allow(client).to receive(:project).with(7).and_return(project)

    expect(access.contributor_logins).to eq([nil, nil])
  end

  describe "#synchronise_repo" do
    it "clones with the deploy token when the scraper has one" do
      scraper.forge_credentials.create!(kind: "deploy_token", token: "dt", username: "gitlab+deploy-token-1")
      allow(Morph::GitSync).to receive(:synchronise)

      expect(access.synchronise_repo).to be_nil
      expect(Morph::GitSync).to have_received(:synchronise).with(scraper.repo_path, "https://gitlab.com/acme/planning.git", username: "gitlab+deploy-token-1", password: "dt")
    end

    it "clones with the Organization's group deploy token otherwise" do
      org.forge_credentials.create!(kind: "deploy_token", token: "gdt", username: "gitlab+deploy-token-9")
      allow(Morph::GitSync).to receive(:synchronise)

      access.synchronise_repo

      expect(Morph::GitSync).to have_received(:synchronise).with(anything, anything, username: "gitlab+deploy-token-9", password: "gdt")
    end

    it "clones with the group access token if that is what there is" do
      org.forge_credentials.create!(kind: "group_access_token", token: "glpat", expires_at: 1.year.from_now)
      allow(Morph::GitlabClient).to receive(:new).with(access_token: "glpat").and_return(client)
      allow(client).to receive(:project).and_return(project)
      allow(Morph::GitSync).to receive(:synchronise)

      access.synchronise_repo

      expect(Morph::GitSync).to have_received(:synchronise).with(anything, anything, username: "oauth2", password: "glpat")
    end

    it "clones with a collaborator's OAuth token as a last resort" do
      alice_with_token("alice-tok")
      allow(Morph::GitlabClient).to receive(:new).with(access_token: "alice-tok").and_return(client)
      allow(client).to receive(:project).and_return(project)
      allow(Morph::GitSync).to receive(:synchronise)

      access.synchronise_repo

      expect(Morph::GitSync).to have_received(:synchronise).with(anything, anything, username: "oauth2", password: "alice-tok")
    end

    it "reports a failed clone as a sync failure" do
      alice_with_token
      allow(Morph::GitlabClient).to receive(:new).and_return(client)
      allow(client).to receive(:project).and_return(project)
      allow(Morph::GitSync).to receive(:synchronise).and_raise(Morph::GitSync::Failed)

      expect(access.synchronise_repo.kind).to eq(:sync_failed)
    end
  end

  describe "#api_credential_missing?" do
    it "is true when a clone credential exists but nothing can reach the API" do
      scraper.forge_credentials.create!(kind: "deploy_token", token: "dt", username: "u")

      expect(access.api_credential_missing?).to be true
    end
  end
end
