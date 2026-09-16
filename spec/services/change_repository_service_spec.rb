# typed: false
# frozen_string_literal: true

require "spec_helper"

describe ChangeRepositoryService do
  let(:forge) { Morph::Forge.for("gitlab") }
  let(:owner) do
    u = create(:user, nickname: "alice")
    u.forge_identities.create!(forge_key: "gitlab", uid: "1", login: "alice-gl", access_token: "tok", token_expires_at: 1.hour.from_now)
    u
  end
  let(:scraper) { create(:scraper, owner: owner, name: "planning", full_name: "alice/planning", forge_repo_id: 1) }
  let(:person) { instance_double(Morph::Forge::PersonClient) }

  before do
    allow(Morph::Environment).to receive(:gitlab_configured?).and_return(true)
    allow_any_instance_of(Morph::Forge::Gitlab).to receive(:person_client).and_return(person) # rubocop:disable RSpec/AnyInstance
    allow(CreateFromForgeWorker).to receive(:perform_async)
  end

  it "keeps the morph.io address even when the repository is named differently on the new forge" do
    moved = Morph::Forge::Repository.new(id: 7, name: "planning-scraper", full_name: "alice-gl/planning-scraper", description: nil, private: false,
                                         default_branch: "main", web_url: "w", clone_url: "c", owner_login: "alice-gl")
    allow(person).to receive(:repository).with("alice-gl/planning-scraper").and_return(moved)

    expect(described_class.call(scraper, forge, "alice-gl/planning-scraper", owner)).to be_nil

    expect(scraper.reload).to have_attributes(name: "planning-scraper", full_name: "alice/planning-scraper", forge_key: "gitlab")
  end

  it "drops any project deploy token the old repository had" do
    scraper.forge_credentials.create!(kind: "deploy_token", token: "old", username: "u")
    moved = Morph::Forge::Repository.new(id: 7, name: "planning", full_name: "alice-gl/planning", description: nil, private: false,
                                         default_branch: "main", web_url: "w", clone_url: "c", owner_login: "alice-gl")
    allow(person).to receive(:repository).and_return(moved)

    described_class.call(scraper, forge, "alice-gl/planning", owner)

    expect(scraper.forge_credentials).to be_empty
  end

  it "says so when the user has not connected the new forge" do
    owner.forge_identity("gitlab").destroy!
    owner.reload

    expect(described_class.call(scraper, forge, "alice-gl/planning", owner)).to include("not connected a GitLab account")
  end
end
