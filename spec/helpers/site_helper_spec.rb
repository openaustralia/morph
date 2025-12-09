# typed: false
# frozen_string_literal: true

require "spec_helper"

describe SiteHelper do
  describe "#hostname" do
    context "when domain is localhost" do
      before do
        allow(Morph::Application.default_url_options).to receive(:[]).with(:host).and_return("localhost:3000")
      end

      it "returns localhost without subdomain" do
        expect(helper.hostname("api")).to eq("localhost:3000")
      end
    end

    context "when domain is production" do
      before do
        allow(Morph::Application.default_url_options).to receive(:[]).with(:host).and_return("morph.io")
      end

      it "returns domain without subdomain when subdomain is nil" do
        expect(helper.hostname).to eq("morph.io")
      end

      it "returns domain without subdomain when subdomain is blank" do
        expect(helper.hostname("")).to eq("morph.io")
      end

      it "returns subdomain with domain" do
        expect(helper.hostname("api")).to eq("api.morph.io")
      end
    end

    context "when host is not configured" do
      before do
        allow(Morph::Application.default_url_options).to receive(:[]).with(:host).and_return(nil)
      end

      it "defaults to morph.io" do
        expect(helper.hostname("api")).to eq("api.morph.io")
      end
    end
  end

  describe "#host_protocol" do
    it "returns configured protocol" do
      allow(Morph::Application.default_url_options).to receive(:[]).with(:protocol).and_return("https")
      expect(helper.host_protocol).to eq("https")
    end

    it "defaults to http when not configured" do
      allow(Morph::Application.default_url_options).to receive(:[]).with(:protocol).and_return(nil)
      expect(helper.host_protocol).to eq("http")
    end
  end

  describe "#host_origin" do
    before do
      allow(Morph::Application.default_url_options).to receive(:[]).with(:protocol).and_return("https")
      allow(Morph::Application.default_url_options).to receive(:[]).with(:host).and_return("morph.io")
    end

    it "combines protocol and hostname" do
      expect(helper.host_origin).to eq("https://morph.io")
    end

    it "combines protocol and hostname with subdomain" do
      expect(helper.host_origin("api")).to eq("https://api.morph.io")
    end
  end
end
