# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::SqliteDiff do
  before { FileUtils.rm_f(["tmp_db1.sqlite", "tmp_db2.sqlite"]) }

  after { FileUtils.rm_f(["tmp_db1.sqlite", "tmp_db2.sqlite"]) }

  let(:db1) do
    # Create an sqlite database
    db = SQLite3::Database.new("tmp_db1.sqlite")
    db.execute("CREATE TABLE foo (v1 text, v2 real);")
    db.execute("INSERT INTO foo VALUES ('hello', 2.3)")
    db
  end

  let!(:db2) do
    # Make an identical version
    FileUtils.cp(db1.filename, "tmp_db2.sqlite")
    SQLite3::Database.new("tmp_db2.sqlite")
  end

  describe ".diffstat" do
    it "shows that nothing has changed" do
      expect(described_class.diffstat("tmp_db1.sqlite", "tmp_db2.sqlite")).to eq(
        "tables" => {
          "added" => [],
          "removed" => [],
          "changed" => [],
          "unchanged" => [
            {
              "name" => "foo",
              "records" => { "counts" => { "added" => 0, "removed" => 0, "changed" => 0, "unchanged" => 1 } }
            }
          ],
          "counts" => { "added" => 0, "removed" => 0, "changed" => 0, "unchanged" => 1 }
        },
        "records" => { "counts" => { "added" => 0, "removed" => 0, "changed" => 0, "unchanged" => 1 } }
      )
    end

    it "shows a new table" do
      db2.execute("CREATE TABLE bar (v1 text, v2 real)")
      expect(described_class.diffstat("tmp_db1.sqlite", "tmp_db2.sqlite")).to eq(
        "tables" => {
          "added" => [
            {
              "name" => "bar",
              "records" => { "counts" => { "added" => 0, "removed" => 0, "changed" => 0, "unchanged" => 0 } }
            }
          ],
          "removed" => [],
          "changed" => [],
          "unchanged" => [
            {
              "name" => "foo",
              "records" => { "counts" => { "added" => 0, "removed" => 0, "changed" => 0, "unchanged" => 1 } }
            }
          ],
          "counts" => { "added" => 1, "removed" => 0, "changed" => 0, "unchanged" => 1 }
        },
        "records" => { "counts" => { "added" => 0, "removed" => 0, "changed" => 0, "unchanged" => 1 } }
      )
    end

    it "shows a deleted table" do
      db2.execute("DROP TABLE foo")
      expect(described_class.diffstat("tmp_db1.sqlite", "tmp_db2.sqlite")).to eq(
        "tables" => {
          "added" => [],
          "removed" => [
            {
              "name" => "foo",
              "records" => { "counts" => { "added" => 0, "removed" => 1, "changed" => 0, "unchanged" => 0 } }
            }
          ],
          "changed" => [],
          "unchanged" => [],
          "counts" => { "added" => 0, "removed" => 1, "changed" => 0, "unchanged" => 0 }
        },
        "records" => { "counts" => { "added" => 0, "removed" => 1, "changed" => 0, "unchanged" => 0 } }
      )
    end

    it "shows an added and a deleted table" do
      db2.execute("CREATE TABLE bar (v1 text, v2 real)")
      db2.execute("DROP TABLE foo")
      expect(described_class.diffstat("tmp_db1.sqlite", "tmp_db2.sqlite")).to eq(
        "tables" => {
          "added" => [
            {
              "name" => "bar",
              "records" => { "counts" => { "added" => 0, "removed" => 0, "changed" => 0, "unchanged" => 0 } }
            }
          ],
          "removed" => [
            {
              "name" => "foo",
              "records" => { "counts" => { "added" => 0, "removed" => 1, "changed" => 0, "unchanged" => 0 } }
            }
          ],
          "changed" => [],
          "unchanged" => [],
          "counts" => { "added" => 1, "removed" => 1, "changed" => 0, "unchanged" => 0 }
        },
        "records" => { "counts" => { "added" => 0, "removed" => 1, "changed" => 0, "unchanged" => 0 } }
      )
    end

    it "shows a changed table (because of a schema change)" do
      db2.execute("ALTER TABLE foo ADD v3 text")
      expect(described_class.diffstat("tmp_db1.sqlite", "tmp_db2.sqlite")).to eq(
        "tables" => {
          "added" => [],
          "removed" => [],
          "changed" => [
            {
              "name" => "foo",
              "records" => { "counts" => { "added" => 0, "removed" => 0, "changed" => 1, "unchanged" => 0 } }
            }
          ],
          "unchanged" => [],
          "counts" => { "added" => 0, "removed" => 0, "changed" => 1, "unchanged" => 0 }
        },
        "records" => { "counts" => { "added" => 0, "removed" => 0, "changed" => 1, "unchanged" => 0 } }
      )
    end

    it "shows a new record on an unchanged table" do
      db2.execute("INSERT INTO foo VALUES ('goodbye', 3.1)")
      expect(described_class.diffstat("tmp_db1.sqlite", "tmp_db2.sqlite")).to eq(
        "tables" => {
          "added" => [],
          "removed" => [],
          "changed" => [],
          "unchanged" => [
            {
              "name" => "foo",
              "records" => { "counts" => { "added" => 1, "removed" => 0, "changed" => 0, "unchanged" => 1 } }
            }
          ],
          "counts" => { "added" => 0, "removed" => 0, "changed" => 0, "unchanged" => 1 }
        },
        "records" => { "counts" => { "added" => 1, "removed" => 0, "changed" => 0, "unchanged" => 1 } }
      )
    end

    it "shows a new record on a new table" do
      db2.execute("CREATE TABLE bar (v1 text, v2 real)")
      db2.execute("INSERT INTO bar VALUES ('goodbye', 3.1)")
      expect(described_class.diffstat("tmp_db1.sqlite", "tmp_db2.sqlite")).to eq(
        "tables" => {
          "added" => [
            "name" => "bar",
            "records" => { "counts" => { "added" => 1, "removed" => 0, "changed" => 0, "unchanged" => 0 } }
          ],
          "removed" => [],
          "changed" => [],
          "unchanged" => [
            "name" => "foo",
            "records" => { "counts" => { "added" => 0, "removed" => 0, "changed" => 0, "unchanged" => 1 } }
          ],
          "counts" => { "added" => 1, "removed" => 0, "changed" => 0, "unchanged" => 1 }
        },
        "records" => { "counts" => { "added" => 1, "removed" => 0, "changed" => 0, "unchanged" => 1 } }
      )
    end

    it "shows everything as added when there was no database to start with" do
      expect(described_class.diffstat("non_existent_file.sqlite", "tmp_db2.sqlite")).to eq(
        "tables" => {
          "added" => [
            {
              "name" => "foo",
              "records" => { "counts" => { "added" => 1, "removed" => 0, "changed" => 0, "unchanged" => 0 } }
            }
          ],
          "removed" => [],
          "changed" => [],
          "unchanged" => [],
          "counts" => { "added" => 1, "removed" => 0, "changed" => 0, "unchanged" => 0 }
        },
        "records" => { "counts" => { "added" => 1, "removed" => 0, "changed" => 0, "unchanged" => 0 } }
      )
      FileUtils.rm("non_existent_file.sqlite")
    end

    it "shows no difference when comparing two non-existent databases" do
      expect(described_class.diffstat("non_existent_file1.sqlite", "non_existent_file2.sqlite")).to eq(
        "tables" => {
          "added" => [],
          "removed" => [],
          "changed" => [],
          "unchanged" => [],
          "counts" => { "added" => 0, "removed" => 0, "changed" => 0, "unchanged" => 0 }
        },
        "records" => { "counts" => { "added" => 0, "removed" => 0, "changed" => 0, "unchanged" => 0 } }
      )
      FileUtils.rm(["non_existent_file1.sqlite", "non_existent_file2.sqlite"])
    end
  end

  describe ".diffstat_table" do
    it "shows no change for two identical sqlite databases" do
      expect(described_class.diffstat_table("foo", db1, db2).serialize).to eq("added" => 0, "removed" => 0, "changed" => 0, "unchanged" => 1)
    end

    it "shows a new record" do
      db2.execute("INSERT INTO foo VALUES ('goodbye', 3.1)")
      expect(described_class.diffstat_table("foo", db1, db2).serialize).to eq("added" => 1, "removed" => 0, "changed" => 0, "unchanged" => 1)
    end

    it "shows a deleted record" do
      db2.execute("DELETE FROM foo where v1='hello'")
      expect(described_class.diffstat_table("foo", db1, db2).serialize).to eq("added" => 0, "removed" => 1, "changed" => 0, "unchanged" => 0)
    end

    it "shows adding a record and deleting a record" do
      db2.execute("INSERT INTO foo VALUES ('goodbye', 3.1)")
      db2.execute("DELETE FROM foo where v1='hello'")
      expect(described_class.diffstat_table("foo", db1, db2).serialize).to eq("added" => 1, "removed" => 1, "changed" => 0, "unchanged" => 0)
    end

    it "shows a record being changed" do
      db2.execute("UPDATE foo SET v1='different' WHERE v1='hello'")
      expect(described_class.diffstat_table("foo", db1, db2).serialize).to eq("added" => 0, "removed" => 0, "changed" => 1, "unchanged" => 0)
    end

    it "is able to handle a large number of records", slow: true do
      FileUtils.rm_f(["tmp_db1.sqlite", "tmp_db2.sqlite"])
      # Create an sqlite database
      db1 = SQLite3::Database.new("tmp_db1.sqlite")
      db1.execute("CREATE TABLE foo (v1 text, v2 real);")
      # Create 1000 random records
      r = Random.new(347)
      (1..1000).each do |i|
        db1.execute("INSERT INTO foo VALUES ('hello#{i}', #{r.rand})")
      end
      # Make an identical version
      FileUtils.cp("tmp_db1.sqlite", "tmp_db2.sqlite")
      db2 = SQLite3::Database.new("tmp_db2.sqlite")
      # Remove 200 random records (but ensure we don't remove the last)
      ids = db2.execute("SELECT ROWID FROM foo ORDER BY RANDOM() LIMIT 201").map(&:first)
      if ids.include?(1000)
        ids.delete(1000)
      else
        ids.delete(ids.first)
      end
      db2.execute("DELETE FROM foo WHERE ROWID IN (#{ids.join(',')})")
      # Update 100 random records
      ids = db2.execute("SELECT ROWID FROM foo ORDER BY RANDOM() LIMIT 100").map(&:first)
      db2.execute("UPDATE foo SET v2=10 WHERE ROWID IN (#{ids.join(',')})")
      # Add 200 new records to that
      (1..200).each do |i|
        db2.execute("INSERT INTO foo VALUES ('hello#{i}', #{r.rand})")
      end
      expect(described_class.diffstat_table("foo", db1, db2, 100).serialize).to eq("added" => 200, "removed" => 200, "changed" => 100, "unchanged" => 700)
    end

    it "compares two empty dbs" do
      FileUtils.rm_f(["tmp_db1.sqlite", "tmp_db2.sqlite"])
      # Create an sqlite database
      db1 = SQLite3::Database.new("tmp_db1.sqlite")
      db1.execute("CREATE TABLE foo (v1 text, v2 real);")
      # Make an identical version
      FileUtils.cp("tmp_db1.sqlite", "tmp_db2.sqlite")
      db2 = SQLite3::Database.new("tmp_db2.sqlite")
      expect(described_class.diffstat_table("foo", db1, db2).serialize).to eq("added" => 0, "removed" => 0, "changed" => 0, "unchanged" => 0)
    end
  end
end
