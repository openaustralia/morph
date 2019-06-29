require 'spec_helper'

describe SearchHelper do
  describe ".no_search_results_message" do
    it { expect(helper.no_search_results_message("scrapers", "bibble")).to eq "Sorry, we couldn't find any scrapers relevant to your search term <strong>“bibble”</strong>." }

    it "should allow html in things" do
      expect(helper.no_search_results_message("scrapers <em>with data</em>".html_safe, "bibble")).to eq "Sorry, we couldn't find any scrapers <em>with data</em> relevant to your search term <strong>“bibble”</strong>."
    end

    it "should allow escape html if things is not html safe" do
      expect(helper.no_search_results_message("scrapers <em>with data</em>", "bibble")).to eq "Sorry, we couldn't find any scrapers &lt;em&gt;with data&lt;/em&gt; relevant to your search term <strong>“bibble”</strong>."
    end

    it "should escape the search term" do
      expect(helper.no_search_results_message("scrapers <em>with data</em>", "<bibble>")).to eq "Sorry, we couldn't find any scrapers &lt;em&gt;with data&lt;/em&gt; relevant to your search term <strong>“&lt;bibble&gt;”</strong>."
    end

    it "should be html safe" do
      expect(helper.no_search_results_message("<foo>", "<bar>")).to be_html_safe
    end
  end
end
