# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::OwnersController, type: :controller do
  render_views

  describe "#index" do
    it "requires login" do
      get :index
      expect(response).to be_redirect
    end

    it "requires admin login" do
      sign_in create(:user, admin: false)
      get :index
      expect(response).to be_redirect
    end

    it "displays index for admin user" do
      sign_in create(:user, admin: true)
      # Create users/organizations with gravatar URLs to avoid nil location error
      create(:user, gravatar_url: "https://gravatar.com/avatar/test1")
      create(:organization, gravatar_url: "https://gravatar.com/avatar/test2")

      get :index
      expect(response).to be_successful
    end
  end
end
