# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::MysqlMigration::Verification do
  subject(:verification) { described_class.new(client, database: database) }

  let(:client) { ActiveRecord::Base.connection.raw_connection }
  let(:database) { ActiveRecord::Base.connection.current_database }

  def differences(source, target) # rubocop:disable Rails/Delegate
    described_class.differences(source, target)
  end

  describe "#snapshot" do
    before { create(:user, name: "Zoë", email: "zoe@example.invalid") }

    it "describes every table apart from the schema bookkeeping ones" do
      tables = verification.snapshot["tables"]

      expect(tables.keys).to include("owners", "runs", "log_lines")
      expect(tables.keys).not_to include("schema_migrations", "ar_internal_metadata")
      expect(tables["owners"]).to include("rows" => 1, "sampled" => false)
    end

    it "is the same when taken twice from the same data" do
      expect(differences(verification.snapshot, verification.snapshot)).to be_empty
    end

    it "records the highest id of each table that has one" do
      expect(verification.snapshot["max_ids"]).to include("owners" => Owner.maximum(:id))
    end
  end

  describe ".differences" do
    let!(:owner) { create(:user, name: "Before") }
    let!(:before_snapshot) { verification.snapshot }

    it "finds a changed value even when the row count is the same" do
      client.query("UPDATE owners SET name = 'After' WHERE id = #{owner.id}")

      expect(differences(before_snapshot, verification.snapshot)).to eq ["owners: value hash differs"]
    end

    it "finds missing rows" do
      client.query("DELETE FROM owners WHERE id = #{owner.id}")

      expect(differences(before_snapshot, verification.snapshot)).to include("owners: 1 rows on the source, 0 on the target")
    end

    it "finds a table that is missing from one side" do
      other = before_snapshot.merge("tables" => before_snapshot["tables"].except("owners"))

      expect(differences(before_snapshot, other)).to eq ["owners: missing from the target"]
      expect(differences(other, before_snapshot)).to eq ["owners: not on the source"]
    end

    it "finds columns that differ" do
      changed = Marshal.load(Marshal.dump(before_snapshot))
      changed["tables"]["owners"]["columns"] = ["id"]

      expect(differences(before_snapshot, changed).first).to start_with("owners: columns differ")
    end
  end

  describe "scoping log_lines to the retained rows" do
    it "counts only the rows the filter selects on the source side" do
      run = create(:run)
      kept = create(:log_line, run: run)
      create(:log_line, run: create(:run))

      scoped = described_class.new(client, database: database, log_lines_where: "id = #{kept.id}").snapshot

      expect(scoped["tables"]["log_lines"]["rows"]).to eq 1
      expect(verification.snapshot["tables"]["log_lines"]["rows"]).to eq 2
    end
  end

  describe "sampling a large scoped table" do
    it "applies the sample to the whole filter, so both sides hash the same rows" do
      stub_const("#{described_class}::FULL_HASH_LIMIT", 1)
      stub_const("#{described_class}::SAMPLE_MODULUS", 2)
      run = create(:run)
      lines = Array.new(6) { create(:log_line, run: run) }
      filter = "run_id IS NULL OR run_id = #{run.id} OR id > #{lines.last.id}"
      source = described_class.new(client, database: database, log_lines_where: filter).snapshot
      client.query("UPDATE log_lines SET text = 'changed' WHERE MOD(id, 2) = 1")

      target = described_class.new(client, database: database, log_lines_where: nil).snapshot
      sampled_rows = LogLine.where("MOD(id, 2) = 0").count

      expect(source["tables"]["log_lines"]).to include("sampled" => true)
      expect(target["tables"]["log_lines"]["hash"]).to eq source["tables"]["log_lines"]["hash"]
      expect(sampled_rows).to be_positive
    end
  end

  describe "#auto_increment_problems" do
    it "is empty when the next id is above the source's highest" do
      create(:user)

      expect(verification.auto_increment_problems(verification.snapshot)).to be_empty
    end

    it "names a table whose next id could collide with rows still to be loaded" do
      problems = verification.auto_increment_problems({ "max_ids" => { "log_lines" => 10_000_000_000 } })

      expect(problems.first).to start_with("log_lines: AUTO_INCREMENT is")
    end
  end

  it "takes CHECKSUM TABLE for each table so a re-run can be shown to change nothing" do
    create(:user)

    first = verification.table_checksums
    expect(first.keys).to include("owners")
    expect(verification.table_checksums).to eq first

    create(:user)
    expect(verification.table_checksums["owners"]).not_to eq first["owners"]
  end
end
