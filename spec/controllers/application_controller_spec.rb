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
    def stub_referer(referer)
      allow(controller).to receive(:request).and_return(
        instance_double(ActionDispatch::Request, referer: referer, host: "morph.io")
      )
    end

    def after_sign_out_path
      controller.send(:after_sign_out_path_for, :any_scope)
    end

    before do
      allow(controller).to receive(:root_path).and_return(root_path)
    end

    it "returns the referer path when the referer is on our own host" do
      stub_referer("https://morph.io/some_user/some_scraper")

      expect(after_sign_out_path).to eq "/some_user/some_scraper"
    end

    it "defaults to root path when there is no referer" do
      stub_referer(nil)

      expect(after_sign_out_path).to eq root_path
    end

    it "does not redirect to a referer on another host" do
      stub_referer("https://evil.example.com/signed_out")

      expect(after_sign_out_path).to eq root_path
    end

    it "defaults to root path for a relative referer" do
      stub_referer("/some_user/some_scraper")

      expect(after_sign_out_path).to eq root_path
    end

    it "does not produce a protocol-relative redirect from a doubled slash" do
      stub_referer("https://morph.io//evil.example.com/signed_out")

      expect(after_sign_out_path).to eq root_path
    end

    it "does not redirect to a referer with a query string" do
      stub_referer("https://morph.io/some_user/some_scraper?evil=1")

      expect(after_sign_out_path).to eq root_path
    end

    it "does not redirect to a referer with a fragment" do
      stub_referer("https://morph.io/some_user/some_scraper#evil")

      expect(after_sign_out_path).to eq root_path
    end

    it "does not redirect to a deeply nested path" do
      stub_referer("https://morph.io/a/b/c")

      expect(after_sign_out_path).to eq root_path
    end

    it "defaults to root path when the referer is not a valid URI" do
      stub_referer("https://morph.io/some path with spaces")

      expect(after_sign_out_path).to eq root_path
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
