# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe OwnersController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:organization) { create(:organization, nickname: "test_org") }

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

      context "with scrapers in different states" do
        let!(:scraper_no_runs) { create(:scraper, owner: user, name: "no_runs") }
        let!(:scraper_running) { create(:scraper, owner: user, name: "running") }
        let!(:scraper_failed) { create(:scraper, :maximal, auto_run: true, owner: user, name: "failed") }
        let!(:scraper_success) { create(:scraper, owner: user, name: "success") }

        before do
          sign_in user

          # Create runs in different states
          # Running: started but not finished
          create(:run, scraper: scraper_running, owner: user, started_at: 5.minutes.ago, finished_at: nil)
          # Missing metric deliberately since this sometimes happens

          # Failed: finished with non-zero status
          failed_run = create(:run, scraper: scraper_failed, owner: user, started_at: 10.minutes.ago, finished_at: 5.minutes.ago, status_code: 1)
          # Some recent metrics are nearly all NULLs
          create(:metric, run: failed_run)

          # Success: finished with zero status
          successful_run = create(:run, scraper: scraper_success, owner: user, started_at: 10.minutes.ago, finished_at: 5.minutes.ago, status_code: 0)
          create(:metric, :maximal, run: successful_run)
        end

        it "categorizes scrapers correctly" do
          get :show, params: { id: user.nickname }

          # Check that we have the right categories
          running = assigns(:running_scrapers)
          erroring = assigns(:erroring_scrapers)
          other = assigns(:other_scrapers)

          # Verify all scrapers are accounted for
          all_scrapers = running + erroring + other
          expect(all_scrapers).to match_array([scraper_no_runs, scraper_running, scraper_failed, scraper_success])
        end

        it "identifies running scrapers" do
          get :show, params: { id: user.nickname }
          running = assigns(:running_scrapers)

          # Should include scraper with unfinished run
          expect(running).to include(scraper_running) if scraper_running.running?
        end

        it "identifies scrapers requiring attention" do
          get :show, params: { id: user.nickname }
          erroring = assigns(:erroring_scrapers)

          # Should include scraper with failed run
          expect(erroring).to include(scraper_failed) if scraper_failed.requires_attention?
        end

        it "categorizes other scrapers" do
          get :show, params: { id: user.nickname }
          other = assigns(:other_scrapers)

          # Should include scrapers that aren't running or erroring
          [scraper_no_runs, scraper_success].each do |scraper|
            expect(other).to include(scraper) unless scraper.running? || scraper.requires_attention?
          end
        end
      end

      context "with no scrapers" do
        it "has empty scraper categories" do
          get :show, params: { id: user.nickname }
          expect(assigns(:running_scrapers)).to be_empty
          expect(assigns(:erroring_scrapers)).to be_empty
          expect(assigns(:other_scrapers)).to be_empty
        end
      end
    end

    context "when viewing an organization's page" do
      before do
        create(:organizations_user, user: user, organization: organization)
      end

      it "returns http success" do
        get :show, params: { id: organization.nickname }
        expect(response).to have_http_status(:success)
      end

      it "assigns the owner" do
        get :show, params: { id: organization.nickname }
        expect(assigns(:owner)).to eq(organization)
      end

      it "does not assign other_scrapers_contributed_to for organizations" do
        get :show, params: { id: organization.nickname }
        expect(assigns(:other_scrapers_contributed_to)).to be_nil
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
        end.to change(user, :api_key)
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
        post :watch, params: { id: other_user.nickname }
        expect(response).to be_redirect
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
        post :watch, params: { id: organization.nickname }
        expect(response).to be_redirect
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
