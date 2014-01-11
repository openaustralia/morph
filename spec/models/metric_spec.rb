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

  describe ".read_from_string" do
    it "should read in a correctly formatted output" do
      time_output = <<-EOF
Maximum resident set size (kbytes): 3808
Minor (reclaiming a frame) page faults: 292
Major (requiring I/O) page faults: 0
      EOF
      Metric.should_receive(:parse_line).with("Maximum resident set size (kbytes): 3808").and_return([:maxrss, 3808])
      Metric.should_receive(:parse_line).with("Minor (reclaiming a frame) page faults: 292").and_return([:minflt, 292])
      Metric.should_receive(:parse_line).with("Major (requiring I/O) page faults: 0").and_return([:majflt, 0])

      m = Metric.read_from_string(time_output)
      m.maxrss.should == 3808
      m.minflt.should == 292
      m.majflt.should == 0
    end
  end

  describe ".parse_line" do
    it { Metric.parse_line("Maximum resident set size (kbytes): 3808").should == [:maxrss, 3808] }
    it { Metric.parse_line("    Maximum resident set size (kbytes): 3808").should == [:maxrss, 3808] }
    it { Metric.parse_line("Minor (reclaiming a frame) page faults: 292").should == [:minrss, 292]}
    it { Metric.parse_line('Command being timed: "ls"').should be_nil}
    it { Metric.parse_line('User time (seconds): 1.34').should == [:utime, 1.34]}
    it { Metric.parse_line('System time (seconds): 24.45').should == [:stime, 24.45]}
    #it { Metric.parse_line('').should == }
  end
end
