# typed: false
# frozen_string_literal: true

require "spec_helper"

describe DocumentationHelper do
  describe "#improve_button" do
    it "creates link to GitHub with correct file path" do
      result = helper.improve_button("Edit this page", "api.html.haml")
      expect(result).to include("Edit this page")
      expect(result).to include("https://github.com/openaustralia/morph/blob/main/app/views/documentation/api.html.haml")
      expect(result).to include('class="btn btn-default improve pull-right"')
    end
  end

  describe "#substitute_api_params" do
    let(:scraper) { create(:scraper, full_name: "user/scraper") }
    let(:user) { create(:user) }

    it "substitutes scraper URL" do
      result = helper.substitute_api_params("URL: [scraper_url]", scraper: scraper, user: nil, query: "")
      expect(result).to include("user/scraper")
      expect(result).to include("<span class=\"full_name\">")
    end

    it "substitutes API key when user provided" do
      result = helper.substitute_api_params("Key: [api_key]", scraper: scraper, user: user, query: "")
      expect(result).to include(user.api_key)
      expect(result).to include("<span class=\"unescaped-api-key\">")
    end

    it "keeps placeholder when user not provided" do
      result = helper.substitute_api_params("Key: [api_key]", scraper: scraper, user: nil, query: "")
      expect(result).to include("[api_key]")
    end

    it "substitutes query parameter" do
      result = helper.substitute_api_params("Query: [query]", scraper: scraper, user: nil, query: "SELECT * FROM data")
      expect(result).to include("SELECT * FROM data")
      expect(result).to include("<span class=\"unescaped-query\">")
    end

    it "escapes HTML in scraper name" do
      scraper = create(:scraper, full_name: "user/<script>alert('xss')</script>")
      result = helper.substitute_api_params("[scraper_url]", scraper: scraper, user: nil, query: "")
      expect(result).not_to include("<script>")
      expect(result).to include("&lt;script&gt;")
    end

    it "escapes HTML in query" do
      result = helper.substitute_api_params("[query]", scraper: scraper, user: nil, query: "<script>alert('xss')</script>")
      expect(result).not_to include("<script>alert")
      expect(result).to include("&lt;script&gt;")
    end

    it "substitutes all parameters together" do
      result = helper.substitute_api_params("[scraper_url] [api_key] [query]", scraper: scraper, user: user, query: "SELECT *")
      expect(result).to include("user/scraper")
      expect(result).to include(user.api_key)
      expect(result).to include("SELECT *")
    end
  end
end
