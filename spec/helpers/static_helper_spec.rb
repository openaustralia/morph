# typed: false
# frozen_string_literal: true

require "spec_helper"

describe StaticHelper do
  describe "#api_root" do
    it "returns root_url in development" do
      allow(Rails.env).to receive(:development?).and_return(true)
      expect(helper.api_root).to eq(root_url)
    end

    it "returns api.morph.io root_url in production" do
      allow(Rails.env).to receive(:development?).and_return(false)
      expect(helper.api_root).to eq(root_url(host: "api.morph.io"))
    end
  end

  describe "#quote" do
    it "wraps text in html escaped double quotes" do
      expect(helper.quote("hello")).to eq("&quot;hello&quot;")
    end
  end

  describe "#curl_command" do
    it "generates curl command with quoted URL" do
      result = helper.curl_command("user/scraper", "json", "abc123", "SELECT * FROM data", "")
      expect(result).to include("curl &quot;")
      expect(result).to include("user/scraper/data.json")
      expect(result).to include("?key=abc123")
      expect(result).to include("&amp;query=SELECT * FROM data&quot;")
    end
  end

  describe "#api_url_in_html" do
    it "constructs API URL with all parameters" do
      result = helper.api_url_in_html("user/scraper", "json", "abc123", "SELECT * FROM data", "&callback=foo")
      expect(result).to include("user/scraper/data.json")
      expect(result).to include("key=abc123")
      expect(result).to include("query=SELECT * FROM data")
      expect(result).to include("callback=foo")
    end
  end
end
