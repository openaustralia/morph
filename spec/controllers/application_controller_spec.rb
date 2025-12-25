# typed: false
# frozen_string_literal: true

require "spec_helper"

describe ApplicationController do
  let(:controller) { described_class.new }
  let(:root_path) { "/the_root_path" }

  describe "#new_session_path" do
    it "returns a path" do
      allow(controller).to receive(:new_user_session_path).and_return("/test_sign_in")

      path = controller.new_session_path(:any_scope)
      expect(path).to eq "/test_sign_in"
    end
  end

  describe "#after_sign_out_path_for" do
    before do
      allow(controller).to receive(:root_path).and_return(root_path)
    end

    # FIXME: This is not safe to do!
    it "returns referer path" do
      referer = "/some_user/some_scraper"
      allow(controller).to receive(:request).and_return(instance_double(ActionDispatch::Request, referer: referer))

      path = controller.send(:after_sign_out_path_for, :any_scope)
      expect(path).to eq referer
    end

    it "defaults to root path" do
      allow(controller).to receive(:request).and_return(instance_double(ActionDispatch::Request, referer: nil))

      path = controller.send(:after_sign_out_path_for, :any_scope)
      expect(path).to eq root_path
    end
  end

  describe "#current_ability" do
    let(:current_user) { create(:user) }
    let(:ability) { instance_double(ScraperAbility) }

    before do
      allow(controller).to receive(:current_user).and_return(current_user)
      allow(ScraperAbility).to receive(:new).with(current_user).and_return(ability)
    end

    it "returns a new ScraperAbility instance" do
      expect(controller.send(:current_ability)).to eq ability
      expect(ScraperAbility).to have_received(:new).with(current_user)
    end

    it "memoizes the ability" do
      ability1 = controller.send(:current_ability)
      ability2 = controller.send(:current_ability)
      expect(ability1).to eq ability2
    end
  end
end
