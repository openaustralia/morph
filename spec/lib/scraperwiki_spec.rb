require 'spec_helper'

describe Scraperwiki do
  describe "#sqlite_database" do
    it "should get the scraperwiki sqlite database via their api" do
      response, database = double, double
      # Ick
      Faraday.should_receive(:get).with("https://classic.scraperwiki.com/scrapers/export_sqlite/blue-mountains/").and_return(response)
      response.should_receive(:body).and_return(database)

      s = Scraperwiki.new("blue-mountains")
      s.sqlite_database.should == database
    end
  end
end
