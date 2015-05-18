require 'spec_helper'

describe ScrapersHelper do
  describe "#is_url?" do
    it { expect(helper.is_url?("foobar")).to eq false }
    it { expect(helper.is_url?("http://example.com blah")).to eq false }
    it { expect(helper.is_url?("ftp://example.com/no_ftp")).to eq false }
    it { expect(helper.is_url?('<a href="http://example.com">blah</a>')).to eq false }
    it { expect(helper.is_url?("http://example.com")).to eq true }
    it { expect(helper.is_url?("http://example.com/#anchor")).to eq true }
  end

  describe "#scraper_description" do
    let(:scraper) { Scraper.new }

    context "scraper description is blank" do
      it { expect(helper.scraper_description(scraper)).to eq 'A scraper to collect structured data from the web.'}
    end

    context "scraper description is not blank" do
      before :each do
        allow(scraper).to receive(:description).and_return('Foo bar')
      end

      it { expect(helper.scraper_description(scraper)).to eq 'Foo bar'}
    end
  end
end
