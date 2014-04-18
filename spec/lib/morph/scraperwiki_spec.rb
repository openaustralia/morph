require 'spec_helper'

describe Morph::Scraperwiki do
  describe "#sqlite_database" do
    it "should get the scraperwiki sqlite database via their api" do
      result = double
      Morph::Scraperwiki.should_receive(:content).with("https://classic.scraperwiki.com/scrapers/export_sqlite/blue-mountains.sqlite").and_return(result)

      s = Morph::Scraperwiki.new("blue-mountains")
      s.sqlite_database.should == result
    end

    it "should raise an exception if the dataproxy connection time out" do
      result = "The dataproxy connection timed out, please retry. This is why."
      Morph::Scraperwiki.should_receive(:content).with("https://classic.scraperwiki.com/scrapers/export_sqlite/blue-mountains.sqlite").and_return(result)

      s = Morph::Scraperwiki.new("blue-mountains")
      expect { s.sqlite_database }.to raise_error result
    end
  end

  describe ".content" do
    it "should grab the contents of a url" do
      response, data = double, double
      Faraday.should_receive(:get).with("http://foo.com").and_return(response)
      response.should_receive(:body).and_return(data)
      response.should_receive(:success?).and_return(true)
      Morph::Scraperwiki.content("http://foo.com").should == data
    end
  end

  describe '#exists?' do
    it { Morph::Scraperwiki.new(nil).exists?.should_not be_true }
    it { Morph::Scraperwiki.new('').exists?.should_not be_true }
  end
end
