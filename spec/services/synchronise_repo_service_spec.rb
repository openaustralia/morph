# typed: false
# frozen_string_literal: true

require "spec_helper"

describe SynchroniseRepoService do
  let(:owner) { create(:user, :on_github, nickname: "alice") }
  let(:scraper) { create(:scraper, owner: owner, name: "planning", private: false) }
  let(:forge) { instance_double(Morph::Forge::Github, repository_access: access) }
  let(:access) { instance_double(Morph::Forge::RepositoryAccess) }
  let(:no_access) { Morph::Forge::Error.new(kind: :no_access_to_repo, message: "no", message_html: "no") }

  before do
    allow(Morph::Forge).to receive(:for).with("github").and_return(forge)
    allow(access).to receive(:api_credential_missing?).and_return(false)
  end

  it "stops at the first thing wrong and returns it" do
    allow(access).to receive(:confirm_has_access).and_return(no_access)
    allow(access).to receive(:private_repository)

    expect(described_class.call(scraper)).to eq(no_access)
    expect(access).not_to have_received(:private_repository)
  end

  it "asks for the repository to be made public when it is private but the scraper is not" do
    allow(access).to receive_messages(confirm_has_access: nil, private_repository: [true, nil])

    expect(described_class.call(scraper)).to be_a(described_class::RepoNeedsToBePublic)
  end

  it "asks for the repository to be made private when the scraper is private but it is not" do
    scraper.update!(private: true)
    allow(access).to receive_messages(confirm_has_access: nil, private_repository: [false, nil])

    expect(described_class.call(scraper)).to be_a(described_class::RepoNeedsToBePrivate)
  end

  context "when the repository can be cloned but nobody can reach the forge's API (ADR 0007)" do
    before do
      stale = Morph::Forge::Error.new(kind: :not_connected, message: "nobody signed in", message_html: "nobody signed in")
      allow(access).to receive_messages(confirm_has_access: stale, api_credential_missing?: true, synchronise_repo: nil)
    end

    it "goes ahead on last-known permissions and marks the scraper as having stale permissions" do
      expect(described_class.call(scraper)).to be_nil
      expect(scraper.reload.permissions_stale_since).to be_within(5.seconds).of(Time.zone.now)
    end

    it "does not reset the time the permissions went stale on later runs" do
      scraper.update!(permissions_stale_since: 2.days.ago)

      described_class.call(scraper)

      expect(scraper.reload.permissions_stale_since).to be_within(5.seconds).of(2.days.ago)
    end
  end

  context "when the repository is reachable" do
    before do
      permissions = Morph::Forge::Permissions.new(pull: true, triage: true, push: true, maintain: false, admin: false)
      allow(access).to receive_messages(confirm_has_access: nil, private_repository: [false, nil], synchronise_repo: nil)
      allow(access).to receive(:collaborators).and_return([[Morph::Forge::Collaborator.new(login: "bob", permissions: permissions)], nil])
    end

    it "mirrors contributors and collaborators from the forge, and clears any stale-permissions flag" do
      scraper.update!(permissions_stale_since: 1.day.ago)
      allow(access).to receive(:contributor_logins).and_return([%w[bob carol], nil])

      expect(described_class.call(scraper)).to be_nil
      expect(scraper.reload.permissions_stale_since).to be_nil
      expect(scraper.reload.contributors.map(&:nickname)).to contain_exactly("bob", "carol")
      collaboration = scraper.collaborations.find_by(owner: User.find_by(nickname: "bob"))
      expect(collaboration).to have_attributes(pull: true, triage: true, push: true, maintain: false, admin: false)
    end

    it "leaves contributors alone when the forge cannot say who they are" do
      scraper.update!(contributors: [create(:user, nickname: "dave")])
      allow(access).to receive(:contributor_logins).and_return([nil, nil])

      expect(described_class.call(scraper)).to be_nil
      expect(scraper.reload.contributors.map(&:nickname)).to eq(["dave"])
    end
  end
end
