require 'spec_helper'

describe Scraper do
  context "A scraper with a couple of runs" do
    before :each do
      user = User.create
      @scraper = user.scrapers.create(name: "my scraper")
      metric1 = Metric.create(utime: 10.2, stime: 2.4)
      metric2 = Metric.create(utime: 1.3, stime: 3.5)
      run1 = @scraper.runs.create(metric_id: metric1.id)
      run2 = @scraper.runs.create(metric_id: metric2.id)
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
  end
end
