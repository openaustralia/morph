# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::Forge::Github do
  let(:forge) { described_class.new }
  let(:owner) { create(:user, :on_github, nickname: "alice", github_uid: "42") }
  let(:scraper) do
    build(:scraper, owner: owner, name: "planning", repo_url: "https://github.com/alice/planning",
                    git_url: "git://github.com/alice/planning.git", forge_repo_id: 7)
  end

  before { allow(Morph::Environment).to receive(:github_app_name).and_return("morph-app") }

  it_behaves_like "a forge"

  it "links to the owner's GitHub profile" do
    expect(forge.owner_url(owner)).to eq("https://github.com/alice")
  end

  it "links to a file with GitHub's blob path" do
    allow(scraper).to receive(:default_branch).and_return("main")
    expect(forge.file_url(scraper, "scraper.rb")).to eq("https://github.com/alice/planning/blob/main/scraper.rb")
  end

  it "links to a commit" do
    expect(forge.commit_url(scraper, "abc1234")).to eq("https://github.com/alice/planning/commit/abc1234")
  end

  describe "#connect_url" do
    it "sends the owner to install the Morph GitHub App, suggesting the scraper's repository" do
      url = forge.connect_url(owner, scraper)

      expect(url).to start_with("https://github.com/apps/morph-app/installations/new/permissions?")
      expect(url).to include("suggested_target_id=42").and include("repository_ids=7")
    end

    it "suggests every repository the owner already has on morph.io when no scraper is given" do
      create(:scraper, owner: owner, forge_repo_id: 8)
      create(:scraper, owner: owner, forge_repo_id: 9)

      expect(forge.connect_url(owner)).to include("repository_ids%5B%5D=8").and include("repository_ids%5B%5D=9")
    end
  end

  describe "#repository_access" do
    let(:installation) { instance_double(Morph::GithubAppInstallation) }

    before { allow(Morph::GithubAppInstallation).to receive(:new).with("alice").and_return(installation) }

    it "reports a missing App installation as the forge not being connected, telling the owner where to install it" do
      allow(installation).to receive(:confirm_has_access_to).with("planning")
                                                            .and_return(Morph::GithubAppInstallation::NoAppInstallationForOwner.new)

      error = forge.repository_access(scraper).confirm_has_access

      expect(error.kind).to eq(:not_connected)
      expect(error.message).to include("install the Morph Github App on alice").and include(forge.connect_url(owner, scraper))
    end

    it "reports the App lacking the repository as no access, naming the repository" do
      allow(installation).to receive(:confirm_has_access_to).with("planning")
                                                            .and_return(Morph::GithubAppInstallation::AppInstallationNoAccessToRepo.new)

      error = forge.repository_access(scraper).confirm_has_access

      expect(error.kind).to eq(:no_access_to_repo)
      expect(error.message).to include("needs access to the repository planning")
    end

    it "reports nothing when the App can see the repository" do
      allow(installation).to receive(:confirm_has_access_to).with("planning").and_return(nil)

      expect(forge.repository_access(scraper).confirm_has_access).to be_nil
    end

    it "reports a failed fetch as a sync failure" do
      allow(installation).to receive(:synchronise_repo).and_return(Morph::GithubAppInstallation::SynchroniseRepoError.new)

      error = forge.repository_access(scraper).synchronise_repo

      expect(error.kind).to eq(:sync_failed)
      expect(error.message).to include("problem getting the latest scraper code from GitHub")
    end

    it "passes through collaborators with GitHub's five permissions" do
      permissions = Morph::GithubAppInstallation::Permissions.new(pull: true, triage: false, push: true, maintain: false, admin: true)
      collaborator = Morph::GithubAppInstallation::Collaborator.new(login: "bob", permissions: permissions)
      allow(installation).to receive(:collaborators).with("planning").and_return([[collaborator], nil])

      collaborators, error = forge.repository_access(scraper).collaborators

      expect(error).to be_nil
      expect(collaborators.first).to have_attributes(login: "bob")
      expect(collaborators.first.permissions).to have_attributes(pull: true, push: true, admin: true, triage: false, maintain: false)
    end

    it "lists contributors by login" do
      allow(installation).to receive(:contributor_nicknames).with("planning").and_return([%w[bob carol], nil])

      logins, error = forge.repository_access(scraper).contributor_logins

      expect(error).to be_nil
      expect(logins).to eq(%w[bob carol])
    end
  end
end
