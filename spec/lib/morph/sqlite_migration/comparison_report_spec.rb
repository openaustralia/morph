# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Morph::SqliteMigration::ComparisonReport do
  def report(source, destination)
    comparison = Morph::SqliteMigration::Manifest.compare(
      Morph::SqliteMigration::Manifest.new(source), Morph::SqliteMigration::Manifest.new(destination)
    )
    described_class.new(comparison).to_s
  end

  it "says match and shows both summaries when the copies agree" do
    text = report({ "data/a/x/data.sqlite" => 10 }, { "data/a/x/data.sqlite" => 10 })

    expect(text).to include("sqlite_files")
    expect(text).to include("RESULT: match")
    expect(text).not_to include("differs")
  end

  it "lists problems and flags the differing rows" do
    text = report({ "a" => 1, "b" => 2 }, { "a" => 5, "z" => 1 })

    expect(text).to include("Missing from destination: 1", "  b")
    expect(text).to include("Extra in destination: 1", "  z")
    expect(text).to include("Size differs", "a\t1\t5")
    expect(text).to include("differs")
    expect(text).to include("RESULT: MISMATCH")
  end

  it "truncates long lists" do
    source = (1..25).to_h { |i| ["file#{i}", 1] }

    expect(report(source, {})).to include("Missing from destination: 25", "... and 5 more")
  end
end
