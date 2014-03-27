require 'spec_helper'

describe Scraper do
  context "A scraper with a couple of runs" do
    before :each do
      user = User.create
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        @scraper = user.scrapers.create(name: "my_scraper")
      end
      @time1 = 2.minutes.ago
      @time2 = 1.minute.ago
      @run1 = @scraper.runs.create(finished_at: @time1)
      @run2 = @scraper.runs.create(finished_at: @time2)
      metric1 = Metric.create(utime: 10.2, stime: 2.4, run_id: @run1.id)
      metric2 = Metric.create(utime: 1.3, stime: 3.5, run_id: @run2.id)
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
      it do
        @scraper.scraperwiki_url = "https://classic.scraperwiki.com/scrapers/australian_rainfall/"
        @scraper.scraperwiki_shortname.should == "australian_rainfall"
      end
    end

    describe "#scraperwiki_url" do
      it do
        @scraper.scraperwiki_shortname = "australian_rainfall"
        @scraper.scraperwiki_url.should == "https://classic.scraperwiki.com/scrapers/australian_rainfall/" 
      end

      it do
        @scraper.scraperwiki_shortname = nil
        @scraper.scraperwiki_url.should be_nil
      end

      it do
        @scraper.scraperwiki_shortname = ''
        @scraper.scraperwiki_url.should be_nil
      end
    end

    describe "#latest_successful_run_time" do
      context "The first run is successful" do
        before :each do
          @run1.update_attributes(status_code: 0)
          @run2.update_attributes(status_code: 255)
        end

        it { @scraper.latest_successful_run_time.to_s.should == @time1.to_s }
      end

      context "The second run is successful" do
        before :each do
          @run1.update_attributes(status_code: 255)
          @run2.update_attributes(status_code: 0)
        end

        it { @scraper.latest_successful_run_time.to_s.should == @time2.to_s }
      end

      context "Neither are successful" do
        before :each do
          @run1.update_attributes(status_code: 255)
          @run2.update_attributes(status_code: 255)
        end

        it { @scraper.latest_successful_run_time.should be_nil }
      end

      context "Both are successful" do
        before :each do
          @run1.update_attributes(status_code: 0)
          @run2.update_attributes(status_code: 0)
        end

        it { @scraper.latest_successful_run_time.to_s.should == @time2.to_s }
      end
    end
  end

  describe 'unique names' do
    it 'should not allow duplicate scraper names for a user' do
      user = create :user
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        create :scraper, name: 'my_scraper', owner: user
        build(:scraper, name: 'my_scraper', owner: user).should_not be_valid
      end
    end

    it 'should allow the same scraper name for a different user' do
      user1 = create :user
      user2 = create :user
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        create :scraper, name: 'my_scraper', owner: user1
        build(:scraper, name: 'my_scraper', owner: user2).should be_valid
      end
    end
  end

  describe 'ScraperWiki validations' do
    it 'should be invalid if the scraperwiki shortname is not set' do
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        build(:scraper, scraperwiki_url: 'foobar').should_not be_valid
      end
    end
  end
end
