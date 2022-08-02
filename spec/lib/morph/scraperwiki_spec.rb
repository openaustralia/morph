# frozen_string_literal: true

require "spec_helper"

describe Morph::Scraperwiki do
  describe "#sqlite_database" do
    it "gets the scraperwiki sqlite database via their api" do
      result = double
      allow(described_class).to receive(:content).with("https://classic.scraperwiki.com/scrapers/export_sqlite/blue-mountains.sqlite").and_return(result)

      s = described_class.new("blue-mountains")
      expect(s.sqlite_database).to eq result
    end

    it "raises an exception if the dataproxy connection time out" do
      result = "The dataproxy connection timed out, please retry. This is why."
      allow(described_class).to receive(:content).with("https://classic.scraperwiki.com/scrapers/export_sqlite/blue-mountains.sqlite").and_return(result)

      s = described_class.new("blue-mountains")
      expect { s.sqlite_database }.to raise_error result
    end
  end

  describe ".content" do
    it "grabs the contents of a url" do
      response = double
      data = double
      allow(Faraday).to receive(:get).with("http://foo.com").and_return(response)
      allow(response).to receive(:body).and_return(data)
      allow(response).to receive(:success?).and_return(true)
      expect(described_class.content("http://foo.com")).to eq data
    end
  end

  describe "#exists?" do
    it { expect(described_class.new(nil)).not_to exist }
    it { expect(described_class.new("")).not_to exist }

    it "says non existent scrapers don't exist" do
      VCR.use_cassette("scraperwiki") do
        expect(described_class.new("non_existent_scraper")).not_to exist
      end
    end
  end
end
