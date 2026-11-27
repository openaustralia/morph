# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Morph::SearchMigration::Reindexer do
  let(:out) { StringIO.new }
  let(:search_index) { instance_double(Searchkick::Index, name: "scrapers_test", exists?: true) }
  let(:model) do
    class_double(Scraper, name: "Scraper", count: 3, search_index: search_index, reindex: true)
  end

  let(:client) { instance_double(Elasticsearch::Client, count: { "count" => 3 }) }

  before do
    allow(Searchkick).to receive_messages(server_version: "8.19.24", client: client)
  end

  describe "#reindex" do
    it "rebuilds each index from the database and reports the counts" do
      counts = described_class.new(models: [model], out: out, poll_seconds: 3600).reindex

      expect(model).to have_received(:reindex)
      expect(counts.map(&:name)).to eq(["Scraper"])
      expect(counts.first).to be_match
      expect(counts.first.seconds).to be >= 0
      expect(out.string).to include("Elasticsearch 8.19.24", "Reindexing Scraper (3 rows)", "Finished Scraper: 3 documents")
    end

    it "reports a mismatch when the index is short" do
      allow(client).to receive(:count).and_return({ "count" => 2 })

      counts = described_class.new(models: [model], out: out, poll_seconds: 3600).reindex

      expect(counts.first).not_to be_match
    end

    it "stops the progress thread even if the reindex fails" do
      allow(model).to receive(:reindex).and_raise("boom")
      before = Thread.list.size

      expect { described_class.new(models: [model], out: out, poll_seconds: 3600).reindex }.to raise_error("boom")
      expect(Thread.list.size).to eq(before)
    end
  end

  describe "#counts" do
    it "reads counts without reindexing" do
      counts = described_class.new(models: [model], out: out).counts

      expect(counts.first.index_count).to eq(3)
      expect(client).to have_received(:count).with(index: "scrapers_test")
      expect(model).not_to have_received(:reindex)
    end
  end

  describe "before any index exists" do
    it "counts 0 documents rather than failing" do
      allow(search_index).to receive(:exists?).and_return(false)

      counts = described_class.new(models: [model], out: out).counts

      expect(counts.first.index_count).to eq(0)
      expect(counts.first).not_to be_match
      expect(client).not_to have_received(:count)
    end
  end

  describe ".report and .ok?" do
    def good = described_class::ModelCount.new(name: "Scraper", database_count: 3, index_count: 3)
    def short = described_class::ModelCount.new(name: "Owner", database_count: 5, index_count: 4)

    it "says match when everything agrees" do
      expect(described_class.report([good])).to include("RESULT: match")
    end

    it "flags rows that differ and says MISMATCH" do
      text = described_class.report([good, short])

      expect(text).to include("RESULT: MISMATCH")
      expect(text.lines.grep(/Owner/).first).to include("differs")
    end

    it "also compares with counts taken from the old server" do
      expect(described_class.ok?([good], "Scraper" => 3)).to be true
      expect(described_class.ok?([good], "Scraper" => 2)).to be false
      expect(described_class.report([good], "Scraper" => 2)).to include("RESULT: MISMATCH")
    end
  end

  describe ".parse_source_counts" do
    it "reads Name=count pairs" do
      expect(described_class.parse_source_counts("Scraper=10, Owner=4")).to eq("Scraper" => 10, "Owner" => 4)
    end

    it "accepts nothing" do
      expect(described_class.parse_source_counts("")).to eq({})
    end

    it "rejects anything else" do
      expect { described_class.parse_source_counts("Scraper:10") }.to raise_error(ArgumentError)
    end
  end

  describe Morph::SearchMigration::Reindexer::ProgressMonitor do
    let(:out) { StringIO.new }
    let(:indices) do
      double(stats: {
               "indices" => {
                 "scrapers_test_20260101000000000" => { "primaries" => { "indexing" => { "index_total" => 99 } } },
                 "scrapers_test_20260102000000000" => { "primaries" => { "indexing" => { "index_total" => 50 } } }
               }
             })
    end
    let(:model) { class_double(Scraper, name: "Scraper", search_index: instance_double(Searchkick::Index, name: "scrapers_test")) }

    before { allow(Searchkick).to receive(:client).and_return(instance_double(Elasticsearch::Client, indices: indices)) }

    it "reports the newest index's progress" do
      described_class.new(model, 200, out).tick

      expect(out.string).to eq("  Scraper: 50 of 200 documents (25%)\n")
    end

    it "says nothing if Elasticsearch cannot be asked" do
      allow(indices).to receive(:stats).and_raise("down")

      described_class.new(model, 200, out).tick

      expect(out.string).to eq("")
    end
  end
end
