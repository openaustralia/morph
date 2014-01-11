require 'spec_helper'

describe Metric do
  describe ".command" do
    it "should return the command needed to capture the metric" do
      Metric.command("ls", "time.output").should == "/usr/bin/time -v -o time.output ls"
    end

    it "should do the right thing with a different command" do
      Metric.command("ruby ./scraper.rb", "time.file").should == "/usr/bin/time -v -o time.file ruby ./scraper.rb"
    end
  end
end
