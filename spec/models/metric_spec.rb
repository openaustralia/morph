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

  describe ".params_from_string" do
    context "correctly formatted output" do
      let(:string) {
        <<-EOF
Maximum resident set size (kbytes): 3808
Minor (reclaiming a frame) page faults: 292
Something to be ignored
Major (requiring I/O) page faults: 0
Page size (bytes): 4096
        EOF
      }

      it do
        Morph::TimeCommand.should_receive(:parse_line).with("Maximum resident set size (kbytes): 3808").and_return([:maxrss, 3808])
        Morph::TimeCommand.should_receive(:parse_line).with("Minor (reclaiming a frame) page faults: 292").and_return([:minflt, 292])
        Morph::TimeCommand.should_receive(:parse_line).with("Something to be ignored").and_return(nil)
        Morph::TimeCommand.should_receive(:parse_line).with("Major (requiring I/O) page faults: 0").and_return([:majflt, 0])
        Morph::TimeCommand.should_receive(:parse_line).with("Page size (bytes): 4096").and_return([:page_size, 4096])
        # There's a bug in GNU time 1.7 which wrongly reports the maximum resident set size on the version of Ubuntu that we're using
        # See https://groups.google.com/forum/#!topic/gnu.utils.help/u1MOsHL4bhg
        Metric.params_from_string(string).should == {
          maxrss: 952, minflt: 292, majflt: 0}
      end
    end
  end

  describe ".parse_line" do
    it { Metric.parse_line('Command being timed: "ls"').should be_nil}
    it { Metric.parse_line('Percent of CPU this job got: 0%').should be_nil }
    it { Metric.parse_line('Elapsed (wall clock) time (h:mm:ss or m:ss): 0:00.00').should == [:wall_time, 0]}
    it { Metric.parse_line('Elapsed (wall clock) time (h:mm:ss or m:ss): 2:02.04').should == [:wall_time, 122.04]}
    it { Metric.parse_line('Elapsed (wall clock) time (h:mm:ss or m:ss): 1:02:02.04').should == [:wall_time, 3722.04]}
    it { Metric.parse_line('User time (seconds): 1.34').should == [:utime, 1.34]}
    it { Metric.parse_line('System time (seconds): 24.45').should == [:stime, 24.45]}
    it { Metric.parse_line("Maximum resident set size (kbytes): 3808").should == [:maxrss, 3808] }
    it { Metric.parse_line("    Maximum resident set size (kbytes): 3808").should == [:maxrss, 3808] }
    it { Metric.parse_line('Minor (reclaiming a frame) page faults: 312').should == [:minflt, 312]}
    it { Metric.parse_line('Major (requiring I/O) page faults: 2').should == [:majflt, 2]}
    it { Metric.parse_line('File system inputs: 480').should == [:inblock, 480]}
    it { Metric.parse_line('File system outputs: 23').should == [:oublock, 23]}
    it { Metric.parse_line('Voluntary context switches: 43').should == [:nvcsw, 43]}
    it { Metric.parse_line('Involuntary context switches: 65').should == [:nivcsw, 65]}
    it { Metric.parse_line('Page size (bytes): 4096').should == [:page_size, 4096]}
  end
end
