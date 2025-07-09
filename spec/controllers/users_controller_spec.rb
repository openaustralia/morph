# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe UsersController, type: :controller do
  let(:user) { create(:user) }

  describe "GET #index" do
    context "when authenticated" do
      before { sign_in user }

      it "returns http success for html" do
        get :index
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/html")
      end

      it "returns http success for json" do
        get :index, format: :json
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")
      end

      it "paginates users for html" do
        create_list(:user, 3)
        get :index
        expect(assigns(:users)).to respond_to(:current_page)
      end
    end

    context "when a guest" do
      it "returns http success" do
        get :index
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET #watching" do
    before { sign_in user }

    it "returns http success" do
      get :watching, params: { id: user.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #stats" do
    before { sign_in user }

    it "returns http success" do
      get :stats
      expect(response).to have_http_status(:success)
    end
  end

  describe "authorization" do
    it "redirects to sign in for watching if not signed in" do
      get :watching, params: { id: user.id }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects to sign in for stats if not signed in" do
      get :stats
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
