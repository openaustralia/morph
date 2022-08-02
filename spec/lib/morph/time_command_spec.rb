# frozen_string_literal: true

require "spec_helper"

describe Morph::TimeCommand do
  describe ".command" do
    it "returns the command needed to capture the metric" do
      expect(described_class.command(["ls"], "time.output")).to eq ["/usr/bin/time", "-v", "-o", "time.output", "ls"]
    end

    it "does the right thing with a different command" do
      expect(described_class.command(["ruby", "./scraper.rb"], "time.file")).to eq ["/usr/bin/time", "-v", "-o", "time.file", "ruby", "./scraper.rb"]
    end
  end

  describe ".params_from_string" do
    context "with correctly formatted output" do
      let(:string) do
        <<~OUTPUT
          Maximum resident set size (kbytes): 3808
          Minor (reclaiming a frame) page faults: 292
          Something to be ignored
          Major (requiring I/O) page faults: 0
          Page size (bytes): 4096
        OUTPUT
      end

      it do
        allow(described_class).to receive(:parse_line).with("Maximum resident set size (kbytes): 3808").and_return([:maxrss, 3808])
        allow(described_class).to receive(:parse_line).with("Minor (reclaiming a frame) page faults: 292").and_return([:minflt, 292])
        allow(described_class).to receive(:parse_line).with("Something to be ignored").and_return(nil)
        allow(described_class).to receive(:parse_line).with("Major (requiring I/O) page faults: 0").and_return([:majflt, 0])
        allow(described_class).to receive(:parse_line).with("Page size (bytes): 4096").and_return([:page_size, 4096])
        # There's a bug in GNU time 1.7 which wrongly reports the maximum resident set size on the version of Ubuntu that we're using
        # See https://groups.google.com/forum/#!topic/gnu.utils.help/u1MOsHL4bhg
        expect(described_class.params_from_string(string)).to eq(
          maxrss: 952, minflt: 292, majflt: 0
        )
      end
    end
  end

  describe ".parse_line" do
    it { expect(described_class.parse_line('Command being timed: "ls"')).to be_nil }
    it { expect(described_class.parse_line("Percent of CPU this job got: 0%")).to be_nil }
    it { expect(described_class.parse_line("Elapsed (wall clock) time (h:mm:ss or m:ss): 0:00.00")).to eq [:wall_time, 0] }
    it { expect(described_class.parse_line("Elapsed (wall clock) time (h:mm:ss or m:ss): 2:02.04")).to eq [:wall_time, 122.04] }
    it { expect(described_class.parse_line("Elapsed (wall clock) time (h:mm:ss or m:ss): 1:02:02.04")).to eq [:wall_time, 3722.04] }
    it { expect(described_class.parse_line("User time (seconds): 1.34")).to eq [:utime, 1.34] }
    it { expect(described_class.parse_line("System time (seconds): 24.45")).to eq [:stime, 24.45] }
    it { expect(described_class.parse_line("Maximum resident set size (kbytes): 3808")).to eq [:maxrss, 3808] }
    it { expect(described_class.parse_line("    Maximum resident set size (kbytes): 3808")).to eq [:maxrss, 3808] }
    it { expect(described_class.parse_line("Minor (reclaiming a frame) page faults: 312")).to eq [:minflt, 312] }
    it { expect(described_class.parse_line("Major (requiring I/O) page faults: 2")).to eq [:majflt, 2] }
    it { expect(described_class.parse_line("File system inputs: 480")).to eq [:inblock, 480] }
    it { expect(described_class.parse_line("File system outputs: 23")).to eq [:oublock, 23] }
    it { expect(described_class.parse_line("Voluntary context switches: 43")).to eq [:nvcsw, 43] }
    it { expect(described_class.parse_line("Involuntary context switches: 65")).to eq [:nivcsw, 65] }
    it { expect(described_class.parse_line("Page size (bytes): 4096")).to eq [:page_size, 4096] }
  end
end
