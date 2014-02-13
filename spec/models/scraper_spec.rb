require 'spec_helper'

describe Scraper do
  context "A scraper with a couple of runs" do
    before :each do
      user = User.create
      @scraper = user.scrapers.create(name: "my scraper")
      run1 = @scraper.runs.create
      run2 = @scraper.runs.create
      metric1 = Metric.create(utime: 10.2, stime: 2.4, run_id: run1.id)
      metric2 = Metric.create(utime: 1.3, stime: 3.5, run_id: run2.id)
    end

    it "#utime" do
      @scraper.utime.should be_within(0.00001).of(11.5)
    end

    it "#stime" do
      @scraper.stime.should be_within(0.00001).of(5.9)
    end

    it "#cpu_time" do
      @scraper.cpu_time.should be_within(0.00001).of(17.4)
    end

    describe "#scraperwiki_shortname" do
      before :each do
        @scraper.scraperwiki_url = "https://classic.scraperwiki.com/scrapers/australian_rainfall/"
      end
      it { @scraper.scraperwiki_shortname.should == "australian_rainfall" }
    end

    describe "#scraperwiki_url" do
      before :each do
        @scraper.scraperwiki_shortname = "australian_rainfall"
      end
      it { @scraper.scraperwiki_url.should == "https://classic.scraperwiki.com/scrapers/australian_rainfall/" }
    end
  end
end
