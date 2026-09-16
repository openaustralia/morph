# typed: false
# frozen_string_literal: true

require "spec_helper"

# The Connected accounts section of an owner's settings page (ADR 0008).
RSpec.describe "Connected accounts", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user, :on_github, nickname: "alice") }

  before do
    allow(Morph::Environment).to receive(:gitlab_configured?).and_return(true)
    sign_in user
  end

  it "lists the forge accounts the owner has connected" do
    get settings_owner_path(user)

    expect(response.body).to include("Connected accounts").and include("GitHub")
  end

  it "offers to connect GitLab when the owner has not" do
    get settings_owner_path(user)

    expect(Nokogiri::HTML(response.body).css("form[action='/users/auth/gitlab'][method='post']")).not_to be_empty
  end

  it "does not offer GitLab when this deployment has no GitLab application" do
    allow(Morph::Environment).to receive(:gitlab_configured?).and_return(false)

    get settings_owner_path(user)

    expect(response.body).not_to include("/users/auth/gitlab")
  end

  describe "disconnecting" do
    before { user.forge_identities.create!(forge_key: "gitlab", uid: "7", login: "alice") }

    it "removes the identity" do
      delete forge_identity_owner_path(user, forge_key: "gitlab")

      expect(user.reload.forge_identity("gitlab")).to be_nil
      expect(response).to redirect_to(settings_owner_path(user))
    end

    it "refuses to remove the last way of signing in" do
      user.forge_identity("github").destroy!

      delete forge_identity_owner_path(user, forge_key: "gitlab")

      expect(user.reload.forge_identity("gitlab")).to be_present
      expect(flash[:alert]).to include("only account you can sign in with")
    end

    it "refuses while scrapers still live on that forge" do
      create(:scraper, owner: user, forge_key: "gitlab")

      delete forge_identity_owner_path(user, forge_key: "gitlab")

      expect(user.reload.forge_identity("gitlab")).to be_present
      expect(flash[:alert]).to include("still have scrapers on GitLab")
    end

    it "is not something you can do to someone else" do
      other = create(:user, :on_github)
      other.forge_identities.create!(forge_key: "gitlab", uid: "8", login: "bob")

      expect { delete forge_identity_owner_path(other, forge_key: "gitlab") }.to raise_error(CanCan::AccessDenied)

      expect(other.reload.forge_identity("gitlab")).to be_present
    end
  end
end
