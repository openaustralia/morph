# typed: false
# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

describe Morph::MysqlMigration::ArchiveManifest do
  let(:dir) { Dir.mktmpdir }
  let(:path) { File.join(dir, "manifest.json") }

  after { FileUtils.remove_entry(dir) }

  it "plans disjoint slices from the first id up to the highest" do
    slices = described_class.new(path).pending_slices(min_id: 1, max_id: 25, slice_rows: 10)

    expect(slices.map { |s| [s.from_id, s.to_id] }).to eq [[1, 10], [11, 20], [21, 25]]
    expect(slices.first.name).to eq "ids-000000000001-000000000010"
  end

  it "starts at the lowest id when the table does not start at 1" do
    slices = described_class.new(path).pending_slices(min_id: 106, max_id: 112, slice_rows: 5)

    expect(slices.map { |s| [s.from_id, s.to_id] }).to eq [[106, 110], [111, 112]]
  end

  it "plans nothing for an empty table" do
    expect(described_class.new(path).pending_slices(min_id: 0, max_id: 0, slice_rows: 10)).to be_empty
  end

  it "resumes after the completed slices, even in a new process" do
    manifest = described_class.new(path)
    slices = manifest.pending_slices(min_id: 1, max_id: 25, slice_rows: 10)
    manifest.complete(slices.first)

    resumed = described_class.new(path)

    expect(resumed.slices.map(&:name)).to eq [slices.first.name]
    expect(resumed.covered_up_to_id).to eq 10
    expect(resumed.pending_slices(min_id: 1, max_id: 25, slice_rows: 10).map(&:from_id)).to eq [11, 21]
  end

  it "tops up from where the archive stopped without touching earlier slices" do
    manifest = described_class.new(path)
    manifest.pending_slices(min_id: 1, max_id: 20, slice_rows: 10).each { |s| manifest.complete(s) }

    top_up = manifest.pending_slices(min_id: 1, max_id: 27, slice_rows: 10)

    expect(top_up.map { |s| [s.from_id, s.to_id] }).to eq [[21, 27]]
    expect(manifest.total_ids_covered).to eq 20
  end

  it "does not write a slice that was not completed" do
    manifest = described_class.new(path)
    manifest.pending_slices(min_id: 1, max_id: 10, slice_rows: 10)

    expect(File.exist?(path)).to be false
  end
end
