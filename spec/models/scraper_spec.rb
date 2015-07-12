require 'spec_helper'

describe Scraper do
  context "A scraper with a couple of runs" do
    before :each do
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        @scraper = create(:scraper)
      end
      @time1 = 2.minutes.ago
      @time2 = 1.minute.ago
      @run1 = @scraper.runs.create(finished_at: @time1)
      @run2 = @scraper.runs.create(finished_at: @time2)
      metric1 = Metric.create(utime: 10.2, stime: 2.4, run_id: @run1.id)
      metric2 = Metric.create(utime: 1.3, stime: 3.5, run_id: @run2.id)
    end

    it "#utime" do
      expect(@scraper.utime).to be_within(0.00001).of(11.5)
    end

    it "#stime" do
      expect(@scraper.stime).to be_within(0.00001).of(5.9)
    end

    it "#cpu_time" do
      expect(@scraper.cpu_time).to be_within(0.00001).of(17.4)
    end

    describe "#scraperwiki_shortname" do
      it do
        @scraper.scraperwiki_url = "https://classic.scraperwiki.com/scrapers/australian_rainfall/"
        expect(@scraper.scraperwiki_shortname).to eq "australian_rainfall"
      end
    end

    describe "#scraperwiki_url" do
      it do
        @scraper.scraperwiki_shortname = "australian_rainfall"
        expect(@scraper.scraperwiki_url).to eq "https://classic.scraperwiki.com/scrapers/australian_rainfall/"
      end

      it do
        @scraper.scraperwiki_shortname = nil
        expect(@scraper.scraperwiki_url).to be_nil
      end

      it do
        @scraper.scraperwiki_shortname = ''
        expect(@scraper.scraperwiki_url).to be_nil
      end
    end

    describe "#latest_successful_run_time" do
      context "The first run is successful" do
        before :each do
          @run1.update_attributes(status_code: 0)
          @run2.update_attributes(status_code: 255)
        end

        it { expect(@scraper.latest_successful_run_time.to_s).to eq @time1.to_s }
      end

      context "The second run is successful" do
        before :each do
          @run1.update_attributes(status_code: 255)
          @run2.update_attributes(status_code: 0)
        end

        it { expect(@scraper.latest_successful_run_time.to_s).to eq @time2.to_s }
      end

      context "Neither are successful" do
        before :each do
          @run1.update_attributes(status_code: 255)
          @run2.update_attributes(status_code: 255)
        end

        it { expect(@scraper.latest_successful_run_time).to be_nil }
      end

      context "Both are successful" do
        before :each do
          @run1.update_attributes(status_code: 0)
          @run2.update_attributes(status_code: 0)
        end

        it { expect(@scraper.latest_successful_run_time.to_s).to eq @time2.to_s }
      end
    end
  end

  describe 'unique names' do
    it 'should not allow duplicate scraper names for a user' do
      user = create :user
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        create :scraper, name: 'my_scraper', owner: user
        expect(build(:scraper, name: 'my_scraper', owner: user)).to_not be_valid
      end
    end

    it 'should allow the same scraper name for a different user' do
      user1 = create :user
      user2 = create :user
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        create :scraper, name: 'my_scraper', owner: user1
        expect(build(:scraper, name: 'my_scraper', owner: user2)).to be_valid
      end
    end
  end

  describe 'ScraperWiki validations' do
    it 'should be invalid if the scraperwiki shortname is not set' do
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        expect(build(:scraper, scraperwiki_url: 'foobar')).to_not be_valid
      end
    end
  end

  describe "#scraped_domains" do
    let(:scraper) { Scraper.new }
    let(:last_run) { mock_model(Run) }

    it "should return an empty array if there is no last run" do
      expect(scraper.scraped_domains).to eq []
    end

    context "there is a last run" do
      before :each do
        allow(scraper).to receive(:last_run).and_return(last_run)
      end

      it "should defer to the last run" do
        result = double
        expect(last_run).to receive(:domains).and_return(result)
        expect(scraper.scraped_domains).to eq result
      end
    end
  end

  context "a scraper with some downloads" do
    let(:scraper) do
      # Doing this to avoid validations getting called
      s = Scraper.new(owner_id: 1)
      s.save(validate: false)
      s
    end
    let(:owner1) { Owner.create }
    let(:owner2) { Owner.create }
    before :each do
      scraper.api_queries.create(owner: owner1, created_at: Date.new(2015, 5, 8))
      scraper.api_queries.create(owner: owner2, created_at: Date.new(2015, 5, 8))
      scraper.api_queries.create(owner: owner2, created_at: Date.new(2015, 5, 8))
      # This api query is before the cut-off date which makes it not visible in public
      scraper.api_queries.create(owner: owner2, created_at: Date.new(2015, 5, 1))
    end

    describe "#download_count_by_owner" do
      it do
        expect(scraper.download_count_by_owner(true)).to eq [[owner2, 3], [owner1, 1]]
      end
    end

    describe "#download_count" do
      it do
        expect(scraper.download_count(true)).to eq 4
      end
    end

    describe "#download_count_by_owner" do
      it do
        expect(scraper.download_count_by_owner(false)).to eq [[owner2, 2], [owner1, 1]]
      end
    end

    describe "#download_count" do
      it do
        expect(scraper.download_count(false)).to eq 3
      end
    end
  end

  context "there is a scraper" do
    let(:scraper) { Scraper.new }

    context "scraper has no data" do
      before :each do
        expect(scraper).to receive(:sqlite_total_rows).and_return(0)
      end

      describe "#has_data?" do
        it{expect(scraper.has_data?).to eq false}
      end
    end

    context "scraper has a data" do
      before :each do
        expect(scraper).to receive(:sqlite_total_rows).and_return(1)
      end

      describe "#has_data?" do
        it{expect(scraper.has_data?).to eq true}
      end
    end

    context "scraper has never run" do
      describe "#finished_successfully?" do
        it{expect(scraper.finished_successfully?).to be_falsey}
      end

      describe "#finished_with_errors?" do
        it{expect(scraper.finished_with_errors?).to be_falsey}
      end
    end

    context "scraper has run but it failed" do
      let(:run) {mock_model(Run, finished_successfully?: false, finished_with_errors?: true)}
      before :each do
        allow(scraper).to receive(:last_run).and_return(run)
      end

      describe "#finished_successfully?" do
        it{expect(scraper.finished_successfully?).to be_falsey}
      end

      describe "#finished_with_errors?" do
        it{expect(scraper.finished_with_errors?).to be_truthy}
      end
    end

    context "scraper has run and it was successful" do
      let(:run) {mock_model(Run, finished_successfully?: true, finished_with_errors?: false)}
      before :each do
        allow(scraper).to receive(:last_run).and_return(run)
      end

      describe "#finished_successfully?" do
        it{expect(scraper.finished_successfully?).to be_truthy}
      end

      describe "#finished_with_errors?" do
        it{expect(scraper.finished_with_errors?).to be_falsey}
      end
    end
  end
end
