# typed: false
# frozen_string_literal: true

require "spec_helper"

describe ScrapersHelper do
  describe "#url?" do
    it { expect(helper.url?("foobar")).to be false }
    it { expect(helper.url?("http://example.com blah")).to be false }
    it { expect(helper.url?("ftp://example.com/no_ftp")).to be false }
    it { expect(helper.url?('<a href="http://example.com">blah</a>')).to be false }
    it { expect(helper.url?("http://example.com")).to be true }
    it { expect(helper.url?("http://example.com/#anchor")).to be true }
  end

  describe "#scraper_description" do
    let(:scraper) { Scraper.new }
    let(:last_run) { mock_model(Run) }
    let(:foo_domain) { mock_model(Domain, name: "foo.com") }
    let(:bar_domain) { mock_model(Domain, name: "bar.com") }
    let(:www_foo_domain) { mock_model(Domain, name: "www.foo.com") }
    let(:www_bar_domain) { mock_model(Domain, name: "www.bar.com") }
    let(:fiddle_domain) { mock_model(Domain, name: "fiddle.com") }

    context "when scraper description is blank" do
      it { expect(helper.scraper_description(scraper)).to eq "A scraper to collect structured data from the web." }
    end

    context "when scraper description is blank and has one scraped domain" do
      before do
        allow(scraper).to receive(:last_run).and_return(last_run)
        allow(scraper).to receive(:scraped_domains).and_return([foo_domain])
      end

      it { expect(helper.scraper_description(scraper)).to eq "A scraper to collect structured data from foo.com." }
    end

    context "when scraper description is blank and has five scraped domains" do
      before do
        allow(scraper).to receive(:last_run).and_return(last_run)
        allow(scraper).to receive(:scraped_domains).and_return([foo_domain, bar_domain, www_foo_domain, www_bar_domain, fiddle_domain])
      end

      it { expect(helper.scraper_description(scraper)).to eq "A scraper to collect structured data from foo.com, bar.com, www.foo.com, and 2 other domains." }
    end

    context "when scraper description is not blank" do
      before do
        allow(scraper).to receive(:description).and_return("Foo bar")
      end

      it { expect(helper.scraper_description(scraper)).to eq "Foo bar" }
    end
  end
end
