# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  describe "GET #github" do
    let(:nickname) { "testuser" }
    let(:uid) { "12345" }
    let(:access_token) { "github_access_token_123" }
    let(:omniauth_hash) do
      OmniAuth::AuthHash.new(
        provider: "github",
        uid: uid,
        info: OmniAuth::AuthHash::InfoHash.new(
          nickname: nickname,
          email: "test@example.com",
          name: "Test User"
        ),
        credentials: OmniAuth::AuthHash.new(
          token: access_token
        )
      )
    end

    let(:github_user_data) do
      Morph::Github::Owner.new(
        login: nickname,
        name: "Test User",
        blog: "https://example.com",
        company: "Test Company",
        location: "Test City",
        email: "test@example.com",
        rels: Morph::Github::OwnerRels.new(
          avatar: Morph::Github::Rel.new(href: "https://gravatar.com/avatar/test")
        ),
        id: uid.to_i
      )
    end

    # rubocop:disable RSpec/AnyInstance
    # We can't easily inject dependencies into Devise internals without it becoming more fragile
    before do
      OmniAuth.config.test_mode = true
      request.env["devise.mapping"] = Devise.mappings[:user]
      request.env["omniauth.auth"] = omniauth_hash

      # Stub GitHub API calls
      allow_any_instance_of(Morph::Github).to receive(:user_from_github).and_return(github_user_data)
      allow_any_instance_of(Morph::Github).to receive(:primary_email).and_return("test@example.com")
      allow_any_instance_of(Morph::Github).to receive(:organizations).and_return([])

      # Stub the flash partial rendering to avoid view rendering issues in controller tests
      allow_any_instance_of(described_class).to receive(:render_to_string)
        .with(partial: "users/sign_in_message")
        .and_return("Welcome! You have signed in successfully.")

      # Stub background job
      allow(RefreshUserOrganizationsWorker).to receive(:perform_async)
    end
    # rubocop:enable RSpec/AnyInstance

    after do
      OmniAuth.config.test_mode = false
    end

    context "when new user signs up" do
      it "creates user and redirects" do
        expect do
          get :github
        end.to change(User, :count).by(1)

        user = User.find_by(nickname: nickname)
        expect(user).to be_present
        expect(user.github_identity).to have_attributes(uid: uid, access_token: access_token)
        expect(response).to have_http_status(:redirect)
      end

      it "sets flash notice" do
        get :github

        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to eq("Welcome! You have signed in successfully.")
      end

      it "signs in the user" do
        get :github

        user = User.find_by(nickname: nickname)
        expect(controller.current_user).to eq(user)
      end

      it "calls watch_all_owners for new user" do
        get :github

        user = User.find_by(nickname: nickname)
        # Verify a user is watching themselves (watch_all_owners behaviour)
        expect(user.watching?(user)).to be true
      end

      it "updates user info from GitHub" do
        get :github

        user = User.find_by(nickname: nickname)
        expect(user.name).to eq("Test User")
        # The gravatar_url includes query parameters in actual implementation
        expect(user.gravatar_url).to start_with("https://gravatar.com/avatar/test")
        expect(user.blog).to eq("https://example.com")
        expect(user.company).to eq("Test Company")
        expect(user.location).to eq("Test City")
        expect(user.email).to eq("test@example.com")
      end

      it "queues background job to refresh organizations" do
        allow(RefreshUserOrganizationsWorker).to receive(:perform_async)
        get :github
        expect(RefreshUserOrganizationsWorker).to have_received(:perform_async)
      end

      it "sets remember_me cookie" do
        get :github
        user = User.find_by(nickname: nickname)
        expect(user.remember_created_at).to be_present
      end
    end

    context "when existing user signs in" do
      let!(:existing_user) { create(:user, :on_github, nickname: nickname, github_uid: uid) }

      it "does not create a new user" do
        expect do
          get :github
        end.not_to change(User, :count)

        expect(response).to have_http_status(:redirect)
      end

      it "signs in the existing user" do
        get :github

        expect(controller.current_user).to eq(existing_user)
      end

      it "sets flash notice" do
        get :github

        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to eq("Welcome! You have signed in successfully.")
      end

      it "updates access token" do
        get :github

        existing_user.reload
        expect(existing_user.github_identity.access_token).to eq(access_token)
      end

      # rubocop:disable RSpec/AnyInstance
      # We can't easily inject dependencies into Devise internals without it becoming more fragile
      it "does not call watch_all_owners for existing user" do
        # User already exists, so we shouldn't be watching again
        expect_any_instance_of(User).not_to receive(:watch_all_owners)
        get :github
      end
      # rubocop:enable RSpec/AnyInstance

      it "refreshes user info from GitHub" do
        existing_user.update(name: "Old Name")
        get :github

        existing_user.reload
        expect(existing_user.name).to eq("Test User")
      end
    end

    context "when user with maximal attributes signs in" do
      let!(:maximal_user) { create(:user, :maximal, nickname: nickname, github_uid: uid) }

      it "handles user with maximal attributes" do
        expect do
          get :github
        end.not_to change(User, :count)

        expect(controller.current_user).to eq(maximal_user)
        expect(response).to have_http_status(:redirect)
      end

      it "updates maximal user attributes" do
        get :github

        maximal_user.reload
        expect(maximal_user.github_identity.access_token).to eq(access_token)
        expect(maximal_user.name).to eq("Test User")
      end
    end

    context "when current_user is already signed in" do
      let(:current_user) { create(:user, :forgeless) }

      before do
        sign_in current_user
      end

      it "links the GitHub account to them rather than switching accounts (ADR 0008)" do
        expect { get :github }.not_to change(User, :count)

        expect(current_user.reload.github_identity).to have_attributes(uid: uid, login: nickname, access_token: access_token)
        expect(controller.current_user).to eq(current_user)
        expect(response).to redirect_to(settings_owner_path(current_user))
      end

      it "handles reconnecting same GitHub account" do
        # The user already has this GitHub account connected
        current_user.update(nickname: nickname)
        current_user.forge_identities.create!(forge_key: "github", uid: uid, login: nickname)

        expect do
          get :github
        end.not_to change(User, :count)

        expect(controller.current_user).to eq(current_user)
      end

      it "refuses to link a GitHub account that already belongs to another Owner" do
        create(:user, :on_github, nickname: nickname, github_uid: uid)

        get :github

        expect(current_user.reload.github_identity).to be_nil
        expect(flash[:alert]).to include("already connected to #{nickname}")
      end
    end

    # rubocop:disable RSpec/AnyInstance
    # We can't easily inject dependencies into Devise internals without it becoming more fragile
    context "when GitHub API errors occur" do
      before do
        allow_any_instance_of(Morph::Github).to receive(:user_from_github)
          .and_raise(Octokit::Unauthorized)
      end

      it "handles Octokit::Unauthorized gracefully" do
        expect do
          get :github
        end.to change(User, :count).by(1)

        user = User.find_by(nickname: nickname)
        # User is created, but GitHub info is not updated (returns false)
        expect(user).to be_present
        expect(user.name).to be_nil
      end
    end

    context "when GitHub API returns NotFound" do
      before do
        allow_any_instance_of(Morph::Github).to receive(:user_from_github)
          .and_raise(Octokit::NotFound)
      end

      it "handles Octokit::NotFound gracefully" do
        expect do
          get :github
        end.to change(User, :count).by(1)

        user = User.find_by(nickname: nickname)
        expect(user).to be_present
        expect(user.name).to be_nil
      end
    end

    context "with edge cases" do
      it "handles user with minimal GitHub profile" do
        minimal_github_data = Morph::Github::Owner.new(
          login: nickname,
          name: nil,
          blog: nil,
          company: nil,
          location: nil,
          email: nil,
          rels: Morph::Github::OwnerRels.new(
            avatar: Morph::Github::Rel.new(href: "https://gravatar.com/avatar/default")
          ),
          id: uid.to_i
        )

        allow_any_instance_of(Morph::Github).to receive(:user_from_github).and_return(minimal_github_data)
        allow_any_instance_of(Morph::Github).to receive(:primary_email).and_return(nil)

        get :github

        user = User.find_by(nickname: nickname)
        expect(user).to be_present
        expect(user.name).to be_nil
        expect(user.blog).to be_nil
        expect(user.company).to be_nil
      end
    end
    # rubocop:enable RSpec/AnyInstance
  end
end
