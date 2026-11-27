# typed: false
# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Morph::SqliteMigration::Manifest do
  def write(root, path, content)
    full = File.join(root, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, content)
  end

  describe ".scan" do
    it "lists regular files with sizes and skips symlinks" do
      Dir.mktmpdir do |root|
        write(root, "data/jane/scraper-one/data.sqlite", "12345")
        write(root, "repos/jane/scraper-one/scraper.rb", "abc")
        File.symlink("data/jane", File.join(root, "link"))

        manifest = described_class.scan(root)

        expect(manifest.sizes).to eq(
          "data/jane/scraper-one/data.sqlite" => 5,
          "repos/jane/scraper-one/scraper.rb" => 3
        )
      end
    end

    it "does not change the directory it reads" do
      Dir.mktmpdir do |root|
        write(root, "data/a/b/data.sqlite", "x")
        before = Dir.glob("#{root}/**/*", File::FNM_DOTMATCH).sort

        described_class.scan(root)

        expect(Dir.glob("#{root}/**/*", File::FNM_DOTMATCH).sort).to eq(before)
      end
    end

    it "refuses a path that is not a directory" do
      expect { described_class.scan("/no/such/fictional/directory") }.to raise_error(ArgumentError, /not a directory/)
    end
  end

  describe "text form" do
    it "round trips through parse and to_s, sorted" do
      text = "b/file\t2\na/file\t1\n"

      expect(described_class.parse(text).to_s).to eq("a/file\t1\nb/file\t2\n")
    end

    it "reads the output of the shell one-liner used on the old server" do
      manifest = described_class.parse("data/jane/x/data.sqlite\t10\n\n")

      expect(manifest.sizes).to eq("data/jane/x/data.sqlite" => 10)
    end

    it "rejects a line that is not path and size" do
      expect { described_class.parse("just a path\n") }.to raise_error(ArgumentError, /line 1/)
      expect { described_class.parse("path\tlots\n") }.to raise_error(ArgumentError, /line 1/)
    end
  end

  describe "#summary" do
    it "totals files and bytes overall, for sqlite files and by top level directory" do
      manifest = described_class.new(
        "data/a/x/data.sqlite" => 100, "data/b/y/data.sqlite" => 50, "repos/a/x/scraper.rb" => 5, "stray" => 1
      )

      expect(manifest.summary).to include(
        files: 4, bytes: 156, sqlite_files: 2, sqlite_bytes: 150,
        data_files: 2, data_bytes: 150, repos_files: 1, repos_bytes: 5, "(top level)_files": 1
      )
    end
  end

  describe ".compare" do
    let(:source) { described_class.new("a" => 1, "b" => 2, "c" => 3) }

    it "matches identical manifests" do
      expect(described_class.compare(source, described_class.new(source.sizes.dup))).to be_match
    end

    it "reports missing, extra and differently sized files" do
      destination = described_class.new("a" => 1, "b" => 9, "d" => 4)

      comparison = described_class.compare(source, destination)

      expect(comparison).not_to be_match
      expect(comparison.missing_from_destination).to eq(["c"])
      expect(comparison.extra_in_destination).to eq(["d"])
      expect(comparison.size_mismatches).to eq([["b", 2, 9]])
    end
  end
end
