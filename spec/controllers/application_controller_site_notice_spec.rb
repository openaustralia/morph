# typed: false
# frozen_string_literal: true

require "spec_helper"

# The notice comes from shared/_site_notice in the application layout, so this
# renders that layout through a throwaway controller.
RSpec.describe ApplicationController, "#site_notice", type: :controller do
  render_views

  controller do
    def index
      render html: "<p>page content</p>".html_safe, layout: true
    end
  end

  let(:read_only_text) { "currently <strong>read-only</strong>" }
  let(:maintenance_text) { "undergoing <strong>maintenance</strong>" }

  context "when the site is in read-only mode" do
    before { SiteSetting.read_only_mode = true }

    it "is shown to a signed out visitor" do
      get :index
      expect(response.body).to include(read_only_text)
    end

    it "is shown to a signed in visitor" do
      sign_in create(:user)
      get :index
      expect(response.body).to include(read_only_text)
    end

    it "does not say the site is under maintenance" do
      get :index
      expect(response.body).not_to include(maintenance_text)
    end
  end

  context "when the site is in maintenance mode" do
    before { SiteSetting.maintenance_mode = true }

    it "is shown to a signed out visitor" do
      get :index
      expect(response.body).to include(maintenance_text)
    end

    it "is shown to a signed in visitor" do
      sign_in create(:user)
      get :index
      expect(response.body).to include(maintenance_text)
    end

    it "does not say the site is read-only" do
      get :index
      expect(response.body).not_to include(read_only_text)
    end
  end

  context "when neither mode is on" do
    it "shows no notice to a signed out visitor" do
      get :index
      expect(response.body).not_to include(read_only_text, maintenance_text)
    end

    it "shows no notice to a signed in visitor" do
      sign_in create(:user)
      get :index
      expect(response.body).not_to include(read_only_text, maintenance_text)
    end
  end

  context "when the notice is switched off again" do
    it "stops showing it without anything being deployed" do
      SiteSetting.maintenance_mode = true
      SiteSetting.maintenance_mode = false
      get :index
      expect(response.body).not_to include(maintenance_text)
    end
  end
end
