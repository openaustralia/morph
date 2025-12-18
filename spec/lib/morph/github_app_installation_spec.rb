# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::GithubAppInstallation, :github do
  let(:installed_bv) { ENV.fetch("GITHUB_APP_INSTALLED_BY", nil) }
  let(:installation) { described_class.new(installed_bv) }
  let(:installation_no_app) { described_class.new("microsoft") }

  before do
    skip "GITHUB_APP_INSTALLED_BY not set" if installed_bv.nil?
  end

  describe "#installed?" do
    it "returns true when app is installed" do
      expect(installation.installed?).to be true
    end

    it "returns false when app is not installed" do
      expect(installation_no_app.installed?).to be false
    end
  end

  describe "#installation_id" do
    it "returns installation id and no error" do
      id, error = installation.installation_id
      expect(id).to be > 0
      expect(error).to be_nil
    end
  end

  describe "#access_token" do
    it "returns valid token" do
      token, error = installation.access_token
      expect(token).to be_a(String)
      expect(token.length).to be > 20
      expect(error).to be_nil
    end
  end

  describe "#confirm_has_access_to" do
    it "returns nil when app has access to repo" do
      error = installation.confirm_has_access_to("yarra")
      expect(error).to be_nil
    end

    it "returns AppInstallationNoAccessToRepo when repo doesn't exist" do
      error = installation.confirm_has_access_to("no-such-scraper")
      expect(error).to be_a(Morph::GithubAppInstallation::AppInstallationNoAccessToRepo)
    end
  end

  describe "#repository_private?" do
    it "returns false for public repo" do
      result, error = installation.repository_private?("yarra")
      expect(error).to be_nil
      expect(result).to be false
    end
  end

  describe "#contributor_nicknames" do
    it "returns array of contributor logins" do
      contributors, error = installation.contributor_nicknames("yass")
      expect(error).to be_nil
      expect(contributors).to be_an(Array)
      expect(contributors).to all(be_a(String))
      expect(contributors).not_to be_empty
    end

    it "returns NoAccessToRepo error for nonexistent repo" do
      contributors, error = installation.contributor_nicknames("no-such-scraper")
      expect(contributors).to eq([])
      expect(error).to be_a(Morph::GithubAppInstallation::NoAccessToRepo)
    end
  end

  describe "#collaborators" do
    it "returns array of collaborators with permissions" do
      collaborators, error = installation.collaborators("yarra")
      expect(error).to be_nil
      expect(collaborators).to be_an(Array)
      expect(collaborators.first).to be_a(Morph::GithubAppInstallation::Collaborator)
      expect(collaborators.first.permissions.admin).to be_in([true, false])
    end

    it "returns NoAccessToRepo error for nonexistent repo" do
      collaborators, error = installation.collaborators("no-such-scraper")
      expect(collaborators).to eq([])
      expect(error).to be_a(Morph::GithubAppInstallation::NoAccessToRepo)
    end
  end
end
