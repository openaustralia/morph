# typed: false
# frozen_string_literal: true

require "spec_helper"

# Signing in with GitLab, and linking a GitLab account to an Owner who is
# already signed in (ADR 0008).
RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  describe "GET #gitlab" do
    let(:omniauth_hash) do
      OmniAuth::AuthHash.new(
        provider: "gitlab",
        uid: "777",
        info: OmniAuth::AuthHash::InfoHash.new(
          username: "alice", name: "Alice Example", email: "alice@example.com", image: "https://gitlab.com/uploads/alice.png"
        ),
        credentials: OmniAuth::AuthHash.new(
          token: "gl_access", refresh_token: "gl_refresh", expires_at: 2.hours.from_now.to_i, expires: true
        )
      )
    end

    before do
      OmniAuth.config.test_mode = true
      request.env["devise.mapping"] = Devise.mappings[:user]
      request.env["omniauth.auth"] = omniauth_hash
    end

    after { OmniAuth.config.test_mode = false }

    context "when nobody is signed in" do
      it "creates a User with a GitLab identity holding the tokens and their expiry" do
        expect { get :gitlab }.to change(User, :count).by(1)

        user = User.find_by(nickname: "alice")
        expect(user.forge_identity("gitlab")).to have_attributes(uid: "777", login: "alice", access_token: "gl_access", refresh_token: "gl_refresh")
        expect(user.forge_identity("gitlab").token_expires_at).to be_within(5.seconds).of(2.hours.from_now)
        expect(controller.current_user).to eq(user)
      end

      it "fills in the profile from what GitLab said at sign-in" do
        get :gitlab

        user = User.find_by(nickname: "alice")
        expect(user).to have_attributes(name: "Alice Example", email: "alice@example.com")
        expect(user.gravatar_url).to start_with("https://gitlab.com/uploads/alice.png")
      end

      it "gives a GitLab login that is already someone's nickname a suffixed nickname" do
        create(:user, nickname: "alice")

        get :gitlab

        user = ForgeIdentity.owner_for("gitlab", "777")
        expect(user.nickname).to eq("alice-gitlab")
        expect(user.forge_identity("gitlab").login).to eq("alice")
      end

      it "finds an existing GitLab user by uid and refreshes their token" do
        existing = create(:user, nickname: "alice")
        existing.forge_identities.create!(forge_key: "gitlab", uid: "777", login: "alice", access_token: "stale")

        expect { get :gitlab }.not_to change(User, :count)

        expect(existing.reload.forge_identity("gitlab").access_token).to eq("gl_access")
        expect(controller.current_user).to eq(existing)
      end

      it "watches all owners for a new sign-up" do
        get :gitlab

        user = User.find_by(nickname: "alice")
        expect(user.watching?(user)).to be true
      end
    end

    context "when a GitHub user is signed in" do
      let(:current_user) { create(:user, :on_github, nickname: "bob") }

      before { sign_in current_user }

      it "links the GitLab account to them and stays signed in as them" do
        expect { get :gitlab }.not_to change(User, :count)

        expect(current_user.reload.forge_identity("gitlab")).to have_attributes(uid: "777", login: "alice", access_token: "gl_access")
        expect(current_user.nickname).to eq("bob")
        expect(controller.current_user).to eq(current_user)
        expect(response).to redirect_to(settings_owner_path(current_user))
      end

      it "refuses to link a GitLab account that already belongs to another Owner" do
        other = create(:user, nickname: "alice")
        other.forge_identities.create!(forge_key: "gitlab", uid: "777", login: "alice")

        get :gitlab

        expect(current_user.reload.forge_identity("gitlab")).to be_nil
        expect(other.reload.forge_identity("gitlab")).to be_present
        expect(flash[:alert]).to include("already connected to alice")
        expect(controller.current_user).to eq(current_user)
      end
    end
  end
end
