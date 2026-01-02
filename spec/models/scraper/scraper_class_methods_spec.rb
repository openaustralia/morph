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
    # Octokit::Client is an external gem
    # rubocop:disable RSpec/VerifiedDoubles
    let(:github_client) { double("Octokit::Client") }
    let(:repo) do
      double(
        "Repository",
        name: "test_repo",
        full_name: "test_owner/test_repo",
        description: "A test repository",
        id: 12345,
        owner: double("Owner", login: "test_owner"),
        rels: double("Rels",
                     html: double("HtmlRel", href: "https://github.com/test_owner/test_repo"),
                     git: double("GitRel", href: "git://github.com/test_owner/test_repo.git"))
      )
    end
    # rubocop:enable RSpec/VerifiedDoubles
    let!(:repo_owner) { create(:user, nickname: "test_owner") }

    before do
      allow(user).to receive(:github).and_return(github_client)
      allow(github_client).to receive(:repository).with("test_owner/test_repo").and_return(repo)
    end

    it "creates new scraper with repository information" do
      scraper = described_class.new_from_github("test_owner/test_repo", user)

      expect(scraper).to be_a(described_class)
      expect(scraper.name).to eq("test_repo")
      expect(scraper.full_name).to eq("test_owner/test_repo")
      expect(scraper.description).to eq("A test repository")
      expect(scraper.github_id).to eq(12345)
      expect(scraper.owner_id).to eq(repo_owner.id)
      expect(scraper.github_url).to eq("https://github.com/test_owner/test_repo")
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
