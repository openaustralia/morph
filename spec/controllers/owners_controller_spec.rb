# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe OwnersController, type: :controller do
  # render_views false # FIXME: add this when the view is fixed

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:organization) { create(:organization) }

  describe "GET #show" do
    context "when viewing a user's page" do
      it "returns http success" do
        get :show, params: { id: user.nickname }
        expect(response).to have_http_status(:success)
      end

      it "assigns the owner" do
        get :show, params: { id: user.nickname }
        expect(assigns(:owner)).to eq(user)
      end

      it "categorizes scrapers by status" do
        sign_in user
        running_scraper = create(:scraper, owner: user)
        allow(running_scraper).to receive(:running?).and_return(true)
        allow(Scraper).to receive_message_chain(:accessible_by, :where).and_return([running_scraper])

        pending("FIXME: The view is broken, and has been for a while in production")
        get :show, params: { id: user.nickname }
        expect(assigns(:running_scrapers)).to include(running_scraper)
      end

      it "shows new_supporter flag from session" do
        sign_in user
        session[:new_supporter] = true
        get :show, params: { id: user.nickname }
        expect(assigns(:new_supporter)).to be(true)
      end

      it "clears new_supporter flag after showing" do
        sign_in user
        session[:new_supporter] = true
        get :show, params: { id: user.nickname }
        expect(session[:new_supporter]).to be(false)
      end

      it "assigns other_scrapers_contributed_to for users" do
        sign_in user
        contributed_scraper = create(:scraper, owner: other_user)
        create(:contribution, user: user, scraper: contributed_scraper)

        get :show, params: { id: user.nickname }
        expect(assigns(:other_scrapers_contributed_to)).not_to be_nil
      end
    end

    context "when viewing an organization's page" do
      before do
        create(:organizations_user, user: user, organization: organization)
      end

      it "returns http success" do
        pending("FIXME: The view is broken, and has been for a while in production")
        get :show, params: { id: organization.nickname }
        expect(response).to have_http_status(:success)
      end

      it "assigns the owner" do
        pending("FIXME: The view is broken, and has been for a while in production")
        get :show, params: { id: organization.nickname }
        expect(assigns(:owner)).to eq(organization)
      end

      it "does not assign other_scrapers_contributed_to for organizations" do
        pending("FIXME: The view is broken, and has been for a while in production")
        get :show, params: { id: organization.nickname }
        expect(assigns(:other_scrapers_contributed_to)).to be_nil
      end
    end

    context "with scrapers in different states" do
      before do
        sign_in user
        @running = create(:scraper, owner: user)
        @erroring = create(:scraper, owner: user)
        @other = create(:scraper, owner: user)

        allow(@running).to receive(:running?).and_return(true)
        allow(@running).to receive(:requires_attention?).and_return(false)

        allow(@erroring).to receive(:running?).and_return(false)
        allow(@erroring).to receive(:requires_attention?).and_return(true)

        allow(@other).to receive(:running?).and_return(false)
        allow(@other).to receive(:requires_attention?).and_return(false)

        allow(Scraper).to receive_message_chain(:accessible_by, :where)
          .and_return([@running, @erroring, @other])
      end

      it "separates running scrapers" do
        pending("FIXME: The view is broken, and has been for a while in production")
        get :show, params: { id: user.nickname }
        expect(assigns(:running_scrapers)).to eq([@running])
      end

      it "separates erroring scrapers" do
        pending("FIXME: The view is broken, and has been for a while in production")
        get :show, params: { id: user.nickname }
        expect(assigns(:erroring_scrapers)).to eq([@erroring])
      end

      it "separates other scrapers" do
        pending("FIXME: The view is broken, and has been for a while in production")
        get :show, params: { id: user.nickname }
        expect(assigns(:other_scrapers)).to eq([@other])
      end
    end

    context "with maximal data" do
      let(:maximal_user) { create(:user, :maximal) }
      let(:maximal_scraper) { create(:scraper, :maximal, owner: maximal_user) }

      it "handles maximal user data" do
        get :show, params: { id: maximal_user.nickname }
        expect(response).to have_http_status(:success)
        expect(assigns(:owner)).to eq(maximal_user)
      end
    end
  end

  describe "GET #settings_redirect" do
    context "when authenticated" do
      before { sign_in user }

      it "redirects to user's settings page" do
        get :settings_redirect
        expect(response).to redirect_to(settings_owner_url(user))
      end
    end

    context "when not authenticated" do
      it "redirects to sign in" do
        get :settings_redirect
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET #settings" do
    context "when viewing own settings" do
      before { sign_in user }

      it "returns http success" do
        get :settings, params: { id: user.nickname }
        expect(response).to have_http_status(:success)
      end

      it "assigns the owner" do
        get :settings, params: { id: user.nickname }
        expect(assigns(:owner)).to eq(user)
      end
    end

    context "when viewing another user's settings" do
      before { sign_in other_user }

      it "denies access" do
        expect do
          get :settings, params: { id: user.nickname }
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "when not authenticated" do
      it "redirects to sign in" do
        get :settings, params: { id: user.nickname }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST #reset_key" do
    context "when resetting own API key" do
      before { sign_in user }

      it "generates a new API key" do
        old_key = user.api_key
        post :reset_key, params: { id: user.nickname }
        user.reload
        expect(user.api_key).not_to eq(old_key)
      end

      it "redirects to settings page" do
        post :reset_key, params: { id: user.nickname }
        expect(response).to redirect_to(settings_owner_url(user))
      end

      it "saves the new key" do
        expect do
          post :reset_key, params: { id: user.nickname }
          user.reload
        end.to(change { user.api_key })
      end
    end

    context "when trying to reset another user's key" do
      before { sign_in other_user }

      it "denies access" do
        expect do
          post :reset_key, params: { id: user.nickname }
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "when not authenticated" do
      it "redirects to sign in" do
        post :reset_key, params: { id: user.nickname }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST #watch" do
    context "when authenticated" do
      before { sign_in user }

      it "toggles watching another user" do
        pending("FIXME: The view is broken, and has been for a while in production")
        expect(user).to receive(:toggle_watch).with(other_user)
        post :watch, params: { id: other_user.nickname }
      end

      it "redirects back to referrer" do
        request.env["HTTP_REFERER"] = owner_url(other_user)
        post :watch, params: { id: other_user.nickname }
        expect(response).to redirect_to(owner_url(other_user))
      end

      it "redirects to root if no referrer" do
        post :watch, params: { id: other_user.nickname }
        expect(response).to redirect_to(root_path)
      end

      it "can watch an organization" do
        create(:organizations_user, user: user, organization: organization)
        expect(user).to receive(:toggle_watch).with(organization)
        pending("FIXME: The view is broken, and has been for a while in production")
        post :watch, params: { id: organization.nickname }
      end
    end

    context "when not authenticated" do
      it "redirects to sign in" do
        post :watch, params: { id: user.nickname }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "authorization" do
    it "requires authentication for settings" do
      get :settings, params: { id: user.nickname }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "requires authentication for reset_key" do
      post :reset_key, params: { id: user.nickname }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "requires authentication for watch" do
      post :watch, params: { id: user.nickname }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "allows unauthenticated users to view show page" do
      get :show, params: { id: user.nickname }
      expect(response).to have_http_status(:success)
    end
  end

  describe "custom ability class" do
    it "uses OwnerAbility and ScraperAbility" do
      sign_in user
      get :show, params: { id: user.nickname }
      expect(controller.send(:current_ability)).to be_a(OwnerAbility)
    end
  end
end
