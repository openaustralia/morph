# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::MysqlMigration::RetainedLogLines do
  subject(:retained) { described_class.new(client, now: now) }

  # The specs run inside a transaction, so the source is read through the same connection
  let(:client) { ActiveRecord::Base.connection.raw_connection }
  let(:now) { Time.now.utc }

  def run_with_line(scraper, status_code:, created_at:)
    run = create(:run, scraper: scraper, status_code: status_code, created_at: created_at)
    create(:log_line, run: run)
    run
  end

  def retained_log_line_ids
    client.query("SELECT id FROM log_lines WHERE #{retained.where_clause}", as: :array).map(&:first).sort
  end

  describe "keeping exactly what Scraper#trim_log_lines keeps" do
    before do
      busy = create(:scraper)
      quiet = create(:scraper)
      old = 60.days.ago
      5.times { run_with_line(busy, status_code: 0, created_at: old) }
      5.times { run_with_line(busy, status_code: 1, created_at: old) }
      run_with_line(busy, status_code: nil, created_at: old)
      2.times { run_with_line(busy, status_code: 0, created_at: 1.day.ago) }
      2.times { run_with_line(quiet, status_code: 0, created_at: old) }
      run_with_line(quiet, status_code: 2, created_at: old)
      LogLine.new(run_id: nil, stream: "stdout", text: "orphan").save!(validate: false)
    end

    it "selects the same log lines as trimming leaves behind" do
      selected = retained_log_line_ids

      Scraper.find_each(&:trim_log_lines)

      expect(selected).to eq LogLine.pluck(:id).sort
    end

    it "does not keep a run whose status is NULL unless it is recent" do
      expect(retained.kept_older_run_ids).not_to include(Run.where(status_code: nil).pick(:id))
    end

    it "counts the rows it selects" do
      expect(retained.expected_row_count).to eq retained_log_line_ids.size
    end
  end

  it "selects every line when all runs are recent" do
    scraper = create(:scraper)
    3.times { run_with_line(scraper, status_code: 0, created_at: 1.day.ago) }

    expect(retained_log_line_ids).to eq LogLine.pluck(:id).sort
    expect(retained.recent_boundary_run_id).to eq Run.minimum(:id)
    expect(retained.kept_older_run_ids).to be_empty
  end

  it "selects only lines without a run when there are no runs" do
    LogLine.new(run_id: nil, stream: "stdout", text: "orphan").save!(validate: false)

    expect(retained.where_clause).to eq "run_id IS NULL"
    expect(retained.recent_boundary_run_id).to be_nil
  end

  it "summarises the filter without printing it" do
    scraper = create(:scraper)
    run_with_line(scraper, status_code: 0, created_at: 90.days.ago)

    expect(retained.summary).to include("kept_older_run_count" => 1, "expected_row_count" => 1)
    expect(retained.summary.keys).not_to include("where_clause")
  end
end
