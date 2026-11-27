# typed: false
# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Morph::SqliteMigration::Sync do
  # Output in the format of rsync 3.x --stats
  let(:stats) do
    <<~OUT
      Number of files: 1,204 (reg: 1,000, dir: 204)
      Number of regular files transferred: 12
      Total file size: 5,000,000,000 bytes
      Total transferred file size: 1,500,000 bytes
      Total bytes sent: 1,234
      Total bytes received: 1,501,000
    OUT
  end
  let(:status) { 0 }
  let(:calls) { [] }
  let(:runner) do
    lambda do |argv, on_line|
      calls << argv
      stats.each_line { |line| on_line.call(line) }
      status
    end
  end

  def build(**options)
    described_class.new(source: "olduser@old.example.org:/srv/scrapers", destination: "/srv/www/rehearsal/shared/db/scrapers",
                        mode: :bulk, runner: runner, **options)
  end

  describe "#command" do
    it "copies the contents of the source into the destination, resumably, with stats" do
      expect(build.command).to eq(
        %w[rsync -a --inplace --stats olduser@old.example.org:/srv/scrapers/ /srv/www/rehearsal/shared/db/scrapers/]
      )
    end

    it "adds the options that were asked for" do
      command = build(dry_run: true, bwlimit: 20_000, ssh_command: "ssh -i /home/deploy/.ssh/fictional_key -o BatchMode=yes").command

      expect(command).to include("--dry-run", "--bwlimit=20000")
      expect(command.each_cons(2)).to include(["-e", "ssh -i /home/deploy/.ssh/fictional_key -o BatchMode=yes"])
    end

    it "never deletes unless asked to" do
      expect(build.command).not_to include("--delete")
    end

    it "deletes, with a limit, when asked" do
      expect(build(mode: :delta, delete: true, max_delete: 50).command).to include("--delete", "--max-delete=50")
    end
  end

  describe "validation" do
    it "needs a source and a destination, and a known mode" do
      expect { described_class.new(source: "", destination: "/x", mode: :bulk) }.to raise_error(described_class::Error, /source/)
      expect { described_class.new(source: "/x", destination: " ", mode: :bulk) }.to raise_error(described_class::Error, /destination/)
      expect { described_class.new(source: "/x", destination: "/y", mode: :other) }.to raise_error(described_class::Error, /mode/)
    end

    it "refuses a password in a location" do
      expect { described_class.new(source: "rsync://olduser:fictional@old.example.org/x", destination: "/y", mode: :bulk) }
        .to raise_error(described_class::Error, /password/)
    end

    it "refuses delete without a limit" do
      expect { build(delete: true) }.to raise_error(described_class::Error, /max_delete/)
    end
  end

  describe "#run" do
    it "records elapsed time and transfer speed from rsync's stats" do
      result = build.run

      expect(result.files_transferred).to eq(12)
      expect(result.file_bytes).to eq(1_500_000)
      expect(result.total_file_bytes).to eq(5_000_000_000)
      expect(result.wire_bytes).to eq(1_502_234)
      expect(result.elapsed_seconds).to be >= 0
      expect(result.bytes_per_second).to be_positive
    end

    it "streams each line to the caller" do
      lines = []

      build.run { |line| lines << line }

      expect(lines).to include("Number of regular files transferred: 12\n")
    end

    it "keeps the login out of the record" do
      record = build.run.to_record

      expect(record[:source]).to eq("old.example.org:/srv/scrapers/")
      expect(record.values.join(" ")).not_to include("olduser")
      expect(build.display_command).not_to include("olduser")
    end

    context "when files vanish during a bulk copy" do
      let(:status) { 24 }

      it "warns rather than failing" do
        expect(build.run.warning).to include("vanished")
      end

      it "fails in the delta pass, where nothing should be changing" do
        expect { build(mode: :delta).run }.to raise_error(described_class::Error, /status 24/)
      end
    end

    context "when rsync fails" do
      let(:status) { 23 }

      it "raises" do
        expect { build.run }.to raise_error(described_class::Error, /status 23/)
      end
    end

    context "with no stats in the output" do
      let(:stats) { "sending incremental file list\n" }

      it "leaves the figures unknown" do
        result = build.run

        expect(result.wire_bytes).to be_nil
        expect(result.bytes_per_second).to be_nil
      end
    end
  end

  describe ".parse_stats" do
    it "reads the older 'Number of files transferred' wording" do
      expect(described_class.parse_stats("Number of files transferred: 7\n")).to eq(files_transferred: 7)
    end
  end

  describe "the default runner" do
    it "runs a command, passes its output on and returns its exit status" do
      lines = []

      status = described_class::DEFAULT_RUNNER.call(["sh", "-c", "echo hello; exit 3"], ->(line) { lines << line })

      expect(lines).to eq(["hello\n"])
      expect(status).to eq(3)
    end
  end

  describe "a real copy", skip: (system("rsync --version", out: File::NULL, err: File::NULL) ? false : "rsync is not installed") do
    it "copies, then a delta pass picks up changes and removes deleted files" do
      Dir.mktmpdir do |dir|
        source = File.join(dir, "source")
        destination = File.join(dir, "destination")
        FileUtils.mkdir_p(File.join(source, "data/jane/one"))
        File.write(File.join(source, "data/jane/one/data.sqlite"), "first")
        File.write(File.join(source, "gone"), "x")

        described_class.new(source: source, destination: destination, mode: :bulk).run
        File.write(File.join(source, "data/jane/one/data.sqlite"), "second version")
        FileUtils.rm(File.join(source, "gone"))
        described_class.new(source: source, destination: destination, mode: :delta, delete: true, max_delete: 5).run

        expect(File.read(File.join(destination, "data/jane/one/data.sqlite"))).to eq("second version")
        expect(File.exist?(File.join(destination, "gone"))).to be false
      end
    end
  end
end
