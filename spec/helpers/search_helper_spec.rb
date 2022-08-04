# typed: false
# frozen_string_literal: true

require "spec_helper"

describe SearchHelper do
  describe ".no_search_results_message" do
    it { expect(helper.no_search_results_message("scrapers", "bibble")).to eq "Sorry, we couldn&#39;t find any scrapers relevant to your search term <strong>“bibble”</strong>." }

    it "allows html in things" do
      expect(helper.no_search_results_message("scrapers <em>with data</em>".html_safe, "bibble")).to eq "Sorry, we couldn&#39;t find any scrapers <em>with data</em> relevant to your search term <strong>“bibble”</strong>."
    end

    it "allows escape html if things is not html safe" do
      expect(helper.no_search_results_message("scrapers <em>with data</em>", "bibble")).to eq "Sorry, we couldn&#39;t find any scrapers &lt;em&gt;with data&lt;/em&gt; relevant to your search term <strong>“bibble”</strong>."
    end

    it "escapes the search term" do
      expect(helper.no_search_results_message("scrapers <em>with data</em>", "<bibble>")).to eq "Sorry, we couldn&#39;t find any scrapers &lt;em&gt;with data&lt;/em&gt; relevant to your search term <strong>“&lt;bibble&gt;”</strong>."
    end

    it "is html safe" do
      expect(helper.no_search_results_message("<foo>", "<bar>")).to be_html_safe
    end
  end
end
