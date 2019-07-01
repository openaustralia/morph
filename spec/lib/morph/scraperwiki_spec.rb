# frozen_string_literal: true

require "spec_helper"

describe Morph::Scraperwiki do
  describe "#sqlite_database" do
    it "should get the scraperwiki sqlite database via their api" do
      result = double
      expect(Morph::Scraperwiki).to receive(:content).with("https://classic.scraperwiki.com/scrapers/export_sqlite/blue-mountains.sqlite").and_return(result)

      s = Morph::Scraperwiki.new("blue-mountains")
      expect(s.sqlite_database).to eq result
    end

    it "should raise an exception if the dataproxy connection time out" do
      result = "The dataproxy connection timed out, please retry. This is why."
      expect(Morph::Scraperwiki).to receive(:content).with("https://classic.scraperwiki.com/scrapers/export_sqlite/blue-mountains.sqlite").and_return(result)

      s = Morph::Scraperwiki.new("blue-mountains")
      expect { s.sqlite_database }.to raise_error result
    end
  end

  describe ".content" do
    it "should grab the contents of a url" do
      response = double
      data = double
      expect(Faraday).to receive(:get).with("http://foo.com").and_return(response)
      expect(response).to receive(:body).and_return(data)
      expect(response).to receive(:success?).and_return(true)
      expect(Morph::Scraperwiki.content("http://foo.com")).to eq data
    end
  end

  describe "#exists?" do
    it { expect(Morph::Scraperwiki.new(nil).exists?).to_not be_truthy }
    it { expect(Morph::Scraperwiki.new("").exists?).to_not be_truthy }

    it "should say non existent scrapers don't exist" do
      VCR.use_cassette("scraperwiki") do
        expect(Morph::Scraperwiki.new("non_existent_scraper").exists?).to_not be_truthy
      end
    end
  end
end
