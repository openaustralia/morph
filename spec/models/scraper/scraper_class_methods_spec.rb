# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Scraper do
  let(:user) { create(:user) }

  # ============================================================================
  # CLASS METHODS
  # ============================================================================

  describe ".running" do
    it "returns scrapers with running runs" do
      scraper1 = create(:scraper)
      scraper2 = create(:scraper)
      scraper3 = create(:scraper)

      scraper1.runs.create!(owner: user, started_at: Time.zone.now)
      scraper2.runs.create!(owner: user, started_at: Time.zone.now)
      scraper3.runs.create!(owner: user, started_at: 1.hour.ago, finished_at: Time.zone.now)

      running = described_class.running
      expect(running).to include(scraper1, scraper2)
      expect(running).not_to include(scraper3)
    end

    it "returns empty array when no scrapers are running" do
      expect(described_class.running).to eq([])
    end
  end

  describe ".new_from_github" do
    let(:user) { create(:user) }
    let(:person) { instance_double(Morph::Forge::PersonClient) }
    let(:repo) do
      Morph::Forge::Repository.new(id: 12345, name: "test_repo", full_name: "test_owner/test_repo", description: "A test repository",
                                   private: false, default_branch: "main", web_url: "https://github.com/test_owner/test_repo",
                                   clone_url: "git://github.com/test_owner/test_repo.git", owner_login: "test_owner")
    end
    let!(:repo_owner) { create(:user, nickname: "test_owner") }

    before do
      allow_any_instance_of(Morph::Forge::Github).to receive(:person_client).and_return(person) # rubocop:disable RSpec/AnyInstance
      allow(person).to receive(:repository).with("test_owner/test_repo").and_return(repo)
    end

    it "creates new scraper with repository information" do
      scraper = described_class.new_from_github("test_owner/test_repo", user)

      expect(scraper).to be_a(described_class)
      expect(scraper.name).to eq("test_repo")
      expect(scraper.full_name).to eq("test_owner/test_repo")
      expect(scraper.description).to eq("A test repository")
      expect(scraper.forge_repo_id).to eq(12345)
      expect(scraper.owner_id).to eq(repo_owner.id)
      expect(scraper.repo_url).to eq("https://github.com/test_owner/test_repo")
      expect(scraper.git_url).to eq("git://github.com/test_owner/test_repo.git")
    end

    it "does not save the scraper" do
      scraper = described_class.new_from_github("test_owner/test_repo", user)
      expect(scraper).to be_new_record
    end
  end

  # ============================================================================
  # BASIC VALIDATIONS
  # ============================================================================

  describe "unique names" do
    it "does not allow duplicate scraper names for a user" do
      user = create :user
      create :scraper, name: "my_scraper", owner: user
      expect(build(:scraper, name: "my_scraper", owner: user)).not_to be_valid
    end

    it "allows the same scraper name for a different user" do
      user1 = create :user
      user2 = create :user
      create :scraper, name: "my_scraper", owner: user1
      expect(build(:scraper, name: "my_scraper", owner: user2)).to be_valid
    end
  end
end
