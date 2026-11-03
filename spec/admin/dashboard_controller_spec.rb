# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::DashboardController, type: :controller do
  render_views

  describe "#index" do
    it "requires login" do
      get :index
      response.should be_redirect
    end

    it "requires admin login" do
      sign_in create(:user, admin: false)
      get :index
      response.should be_redirect
    end

    it "displays index for admin user" do
      sign_in create(:user, admin: true)
      create(:api_query)
      create(:api_query, :maximal)
      get :index
      expect(response).to be_successful
    end
  end

  describe "#toggle_read_only_mode" do
    before { sign_in create(:user, admin: true) }

    it "switches read-only mode on" do
      post :toggle_read_only_mode
      expect(SiteSetting.read_only_mode).to be true
    end

    it "switches read-only mode off" do
      SiteSetting.read_only_mode = true
      post :toggle_read_only_mode
      expect(SiteSetting.read_only_mode).to be false
    end
  end

  describe "#toggle_maintenance_mode" do
    it "requires admin login" do
      sign_in create(:user, admin: false)
      post :toggle_maintenance_mode
      expect(SiteSetting.maintenance_mode).to be false
    end

    context "when signed in as an admin" do
      before { sign_in create(:user, admin: true) }

      it "switches maintenance mode on" do
        post :toggle_maintenance_mode
        expect(SiteSetting.maintenance_mode).to be true
      end

      it "switches maintenance mode off" do
        SiteSetting.maintenance_mode = true
        post :toggle_maintenance_mode
        expect(SiteSetting.maintenance_mode).to be false
      end

      it "returns to the dashboard" do
        post :toggle_maintenance_mode
        expect(response).to redirect_to(admin_dashboard_url)
      end
    end
  end

  describe "#index buttons" do
    before { sign_in create(:user, admin: true) }

    it "offers to switch maintenance mode on when it is off" do
      get :index
      expect(response.body).to include("Show the site-wide maintenance notice")
    end

    it "offers to switch maintenance mode off when it is on" do
      SiteSetting.maintenance_mode = true
      get :index
      expect(response.body).to include("Hide the site-wide maintenance notice")
    end
  end
end
