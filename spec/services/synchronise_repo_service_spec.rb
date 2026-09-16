# typed: false
# frozen_string_literal: true

require "spec_helper"

describe SynchroniseRepoService do
  let(:owner) { create(:user, :on_github, nickname: "alice") }
  let(:scraper) { create(:scraper, owner: owner, name: "planning", private: false) }
  let(:forge) { instance_double(Morph::Forge::Github, repository_access: access) }
  let(:access) { instance_double(Morph::Forge::RepositoryAccess) }
  let(:no_access) { Morph::Forge::Error.new(kind: :no_access_to_repo, message: "no", message_html: "no") }

  before { allow(Morph::Forge).to receive(:for).with("github").and_return(forge) }

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

  context "when the repository is reachable" do
    before do
      permissions = Morph::Forge::Permissions.new(pull: true, triage: true, push: true, maintain: false, admin: false)
      allow(access).to receive_messages(confirm_has_access: nil, private_repository: [false, nil], synchronise_repo: nil)
      allow(access).to receive(:collaborators).and_return([[Morph::Forge::Collaborator.new(login: "bob", permissions: permissions)], nil])
    end

    it "mirrors contributors and collaborators from the forge" do
      allow(access).to receive(:contributor_logins).and_return([%w[bob carol], nil])

      expect(described_class.call(scraper)).to be_nil
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
