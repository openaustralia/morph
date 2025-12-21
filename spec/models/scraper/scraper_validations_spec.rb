# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Scraper do
  let(:user) { create(:user) }

  # ============================================================================
  # VALIDATIONS - GitHub Integration
  # ============================================================================
  # These tests require stubbing external GitHub API calls.
  # All three validation methods run on create, so we stub ALL external calls
  # in each test to prevent VCR errors.
  # ============================================================================

  describe "validations" do
    describe "#not_used_on_github" do
      let(:owner) { create(:user) }
      let(:scraper) { build(:scraper, owner: owner, name: "test_scraper") }
      # Octokit is external gem
      # rubocop:disable RSpec/VerifiedDoubles
      let(:octokit_client) { double("Octokit::Client") }
      # rubocop:enable RSpec/VerifiedDoubles
      let(:installation) { instance_double(Morph::GithubAppInstallation, installed?: true) }

      before do
        # Need to turn off the default skip_github_validations for these tests
        described_class.skip_github_validations = false

        # Stub the GithubAppInstallation check that runs in app_installed_on_owner
        allow(Morph::GithubAppInstallation).to receive(:new).with(owner.nickname).and_return(installation)

        # Stub Octokit client
        allow(Octokit).to receive(:client).and_return(octokit_client)
      end

      after do
        # Restore default behavior
        described_class.skip_github_validations = true
      end

      it "is valid when repository does not exist on GitHub" do
        allow(octokit_client).to receive(:repository?).with(scraper.full_name).and_return(false)

        expect(scraper).to be_valid
      end

      it "is invalid when repository already exists on GitHub" do
        allow(octokit_client).to receive(:repository?).with(scraper.full_name).and_return(true)

        expect(scraper).not_to be_valid
        expect(scraper.errors[:name]).to include("is already taken on GitHub")
      end

      it "skips validation when github_id is present" do
        scraper.github_id = 12345
        # With github_id present, the not_used_on_github validation is skipped entirely
        # But app_has_access_to_repo will run, so we need to stub it
        allow(installation).to receive(:confirm_has_access_to).with(scraper.name).and_return(nil)

        expect(scraper).to be_valid
      end
    end

    describe "#app_installed_on_owner" do
      let(:owner) { create(:user, nickname: "test_user") }
      let(:scraper) { build(:scraper, owner: owner, name: "test_scraper") }
      # Octokit is external gem
      # rubocop:disable RSpec/VerifiedDoubles
      let(:octokit_client) { double("Octokit::Client") }
      # rubocop:enable RSpec/VerifiedDoubles

      before do
        described_class.skip_github_validations = false

        # Stub the Octokit check that runs in not_used_on_github
        allow(Octokit).to receive(:client).and_return(octokit_client)
        allow(octokit_client).to receive(:repository?).with(scraper.full_name).and_return(false)
      end

      after do
        described_class.skip_github_validations = true
      end

      it "is valid when GitHub app is installed for owner" do
        installation = instance_double(Morph::GithubAppInstallation, installed?: true)
        allow(Morph::GithubAppInstallation).to receive(:new).with("test_user").and_return(installation)

        expect(scraper).to be_valid
      end

      it "is invalid when GitHub app is not installed for owner" do
        installation = instance_double(Morph::GithubAppInstallation, installed?: false)
        allow(Morph::GithubAppInstallation).to receive(:new).with("test_user").and_return(installation)

        expect(scraper).not_to be_valid
        expect(scraper.errors[:owner_id]).to be_present
      end
    end

    describe "#app_has_access_to_repo" do
      let(:owner) { create(:user, nickname: "test_user") }
      let(:scraper) { build(:scraper, owner: owner, name: "test_repo", github_id: 12345) }
      # Octokit is external gem
      # rubocop:disable RSpec/VerifiedDoubles
      let(:octokit_client) { double("Octokit::Client") }
      # rubocop:enable RSpec/VerifiedDoubles

      before do
        described_class.skip_github_validations = false

        # Stub the Octokit check - not_used_on_github is skipped when github_id is present,
        # but we still need to provide the stub in case it's called
        allow(Octokit).to receive(:client).and_return(octokit_client)
        allow(octokit_client).to receive(:repository?).and_return(false)
      end

      after do
        described_class.skip_github_validations = true
      end

      it "is valid when app has access to the repository" do
        installation = instance_double(Morph::GithubAppInstallation)
        allow(Morph::GithubAppInstallation).to receive(:new).with("test_user").and_return(installation)
        allow(installation).to receive(:confirm_has_access_to).with("test_repo").and_return(nil)

        expect(scraper).to be_valid
      end

      it "is invalid when app installation does not exist for owner" do
        installation = instance_double(Morph::GithubAppInstallation)
        allow(Morph::GithubAppInstallation).to receive(:new).with("test_user").and_return(installation)
        error = Morph::GithubAppInstallation::NoAppInstallationForOwner.new
        allow(installation).to receive(:confirm_has_access_to).with("test_repo").and_return(error)

        expect(scraper).not_to be_valid
        expect(scraper.errors[:full_name]).to be_present
      end

      it "is invalid when app does not have access to repo" do
        installation = instance_double(Morph::GithubAppInstallation)
        allow(Morph::GithubAppInstallation).to receive(:new).with("test_user").and_return(installation)
        error = Morph::GithubAppInstallation::AppInstallationNoAccessToRepo.new
        allow(installation).to receive(:confirm_has_access_to).with("test_repo").and_return(error)

        expect(scraper).not_to be_valid
        expect(scraper.errors[:full_name]).to be_present
      end

      it "skips validation when github_id is blank" do
        scraper.github_id = nil
        installation = instance_double(Morph::GithubAppInstallation, installed?: true)
        allow(Morph::GithubAppInstallation).to receive(:new).with("test_user").and_return(installation)

        expect(scraper).to be_valid
      end
    end
  end
end
