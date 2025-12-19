# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::ScraperQueueController, type: :controller do
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
end
