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
    context "correctly formatted output" do
      let(:string) {
        <<-EOF
Maximum resident set size (kbytes): 3808
Minor (reclaiming a frame) page faults: 292
Major (requiring I/O) page faults: 0
        EOF
      }

      before :each do
        Metric.should_receive(:parse_line).with("Maximum resident set size (kbytes): 3808").and_return([:maxrss, 3808])
        Metric.should_receive(:parse_line).with("Minor (reclaiming a frame) page faults: 292").and_return([:minflt, 292])
        Metric.should_receive(:parse_line).with("Major (requiring I/O) page faults: 0").and_return([:majflt, 0])
        @m = Metric.read_from_string(string)
      end

      it { @m.maxrss.should == 3808 }
      it { @m.minflt.should == 292 }
      it { @m.majflt.should == 0 }
    end 
  end

  describe ".read_from_file" do
    context "output in a file" do
      let(:filename) { "#{Rails.root}/tmp/time.output" }
      let(:text) { "User time (seconds): 1.12\nVoluntary context switches: 42\n" }

      before(:each) { File.open(filename, "w") {|f| f.write(text)} }
      after(:each) { FileUtils.rm(filename) }

      it "should read from a file" do
        result = double
        Metric.should_receive(:read_from_string).and_return(result)
        Metric.read_from_file(filename).should == result
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
    it { Metric.parse_line('Major (requiring I/O) page faults: 2').should == [:maxflt, 2]}
    it { Metric.parse_line('File system inputs: 480').should == [:inblock, 480]}
    it { Metric.parse_line('File system outputs: 23').should == [:oublock, 23]}
    it { Metric.parse_line('Voluntary context switches: 43').should == [:nvcsw, 43]}
    it { Metric.parse_line('Involuntary context switches: 65').should == [:nivcsw, 65]}
  end
end
