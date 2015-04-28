require 'spec_helper'

describe Morph::Database do
  describe ".clean_utf8_string" do
    it { Morph::Database.clean_utf8_string("This is valid UTF8").should == "This is valid UTF8" }
    it { Morph::Database.clean_utf8_string("Rodolfo Moisés Castañón Fuentes").should == "Rodolfo Moisés Castañón Fuentes" }
    it { Morph::Database.clean_utf8_string("foo\xA2bar").should == "foobar" }
    it { Morph::Database.clean_utf8_string("Casta\xC3\xB1\xC3\xB3n").should == "Castañón" }
  end

  describe '#clear' do
    it "should not attempt to remove the file if it's not there" do
      FileUtils.should_not_receive(:rm)
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        Morph::Database.new(create(:scraper).data_path).clear
      end
    end
  end

  describe '#backup' do
    it "should backup the database file" do
      # Create a fake database file
      File.open("data.sqlite", "w") do |f|
        f.write("This is a fake sqlite file")
      end
      d = Morph::Database.new(".")
      d.backup
      File.read("data.sqlite.backup").should == "This is a fake sqlite file"
      FileUtils.rm(["data.sqlite", "data.sqlite.backup"])
    end

    it "shouldn't do anything if the database file isn't there" do
      d = Morph::Database.new(".")
      d.backup
    end
  end

  describe "#sql_query" do
    let(:database) { Morph::Database.new(".") }
    it { expect { database.sql_query("") }.to raise_error SQLite3::Exception, "No query specified" }
    it { expect { database.sql_query(nil) }.to raise_error SQLite3::Exception, "No query specified" }
  end

  describe "differencing databases" do

    before(:each) do
      FileUtils::rm_f(["tmp_db1.sqlite", "tmp_db2.sqlite"])
      # Create an sqlite database
      @db1 = SQLite3::Database.new("tmp_db1.sqlite")
      @db1.execute("CREATE TABLE foo (v1 text, v2 real);")
      @db1.execute("INSERT INTO foo VALUES ('hello', 2.3)")
      # Make an identical version
      FileUtils::cp("tmp_db1.sqlite", "tmp_db2.sqlite")
      @db2 = SQLite3::Database.new("tmp_db2.sqlite")
    end
    after(:each) { FileUtils::rm_f(["tmp_db1.sqlite", "tmp_db2.sqlite"]) }

    describe ".diffstat_table" do
      it "should show no change for two identical sqlite databases" do
        Morph::Database.diffstat_table("foo", @db1, @db2).should == {added: 0, removed: 0, changed: 0, unchanged: 1}
      end

      it "should show a new record" do
        @db2.execute("INSERT INTO foo VALUES ('goodbye', 3.1)")
        Morph::Database.diffstat_table("foo", @db1, @db2).should == {added: 1, removed: 0, changed: 0, unchanged: 1}
      end

      it "should show a deleted record" do
        @db2.execute("DELETE FROM foo where v1='hello'")
        Morph::Database.diffstat_table("foo", @db1, @db2).should == {added: 0, removed: 1, changed: 0, unchanged: 0}
      end

      it "should show adding a record and deleting a record" do
        @db2.execute("INSERT INTO foo VALUES ('goodbye', 3.1)")
        @db2.execute("DELETE FROM foo where v1='hello'")
        Morph::Database.diffstat_table("foo", @db1, @db2).should == {added: 1, removed: 1, changed: 0, unchanged: 0}
      end

      it "should show a record being changed" do
        @db2.execute("UPDATE foo SET v1='different' WHERE v1='hello'")
        Morph::Database.diffstat_table("foo", @db1, @db2).should == {added: 0, removed: 0, changed: 1, unchanged: 0}
      end

      it "should be able to handle a large number of records", slow: true do
        FileUtils::rm_f(["tmp_db1.sqlite", "tmp_db2.sqlite"])
        # Create an sqlite database
        @db1 = SQLite3::Database.new("tmp_db1.sqlite")
        @db1.execute("CREATE TABLE foo (v1 text, v2 real);")
        # Create 1000 random records
        r = Random.new(347)
        (1..1000).each do |i|
          @db1.execute("INSERT INTO foo VALUES ('hello#{i}', #{r.rand})")
        end
        # Make an identical version
        FileUtils::cp("tmp_db1.sqlite", "tmp_db2.sqlite")
        @db2 = SQLite3::Database.new("tmp_db2.sqlite")
        # Remove 200 random records (but ensure we don't remove the last)
        ids = @db2.execute("SELECT ROWID FROM foo ORDER BY RANDOM() LIMIT 201").map{|r| r.first}
        if ids.include?(1000)
          ids.delete(1000)
        else
          ids.delete(ids.first)
        end
        @db2.execute("DELETE FROM foo WHERE ROWID IN (#{ids.join(',')})")
        # Update 100 random records
        ids = @db2.execute("SELECT ROWID FROM foo ORDER BY RANDOM() LIMIT 100").map{|r| r.first}
        @db2.execute("UPDATE foo SET v2=10 WHERE ROWID IN (#{ids.join(',')})")
        # Add 200 new records to that
        (1..200).each do |i|
          @db2.execute("INSERT INTO foo VALUES ('hello#{i}', #{r.rand})")
        end
        Morph::Database.diffstat_table("foo", @db1, @db2, 100).should == {added: 200, removed: 200, changed: 100, unchanged: 700}
      end

      it "should compare two empty dbs" do
        FileUtils::rm_f(["tmp_db1.sqlite", "tmp_db2.sqlite"])
        # Create an sqlite database
        @db1 = SQLite3::Database.new("tmp_db1.sqlite")
        @db1.execute("CREATE TABLE foo (v1 text, v2 real);")
        # Make an identical version
        FileUtils::cp("tmp_db1.sqlite", "tmp_db2.sqlite")
        @db2 = SQLite3::Database.new("tmp_db2.sqlite")
        Morph::Database.diffstat_table("foo", @db1, @db2).should == {added: 0, removed: 0, changed: 0, unchanged: 0}
      end
    end

    describe ".diffstat" do
      it "should show that nothing has changed" do
        Morph::Database.diffstat("tmp_db1.sqlite", "tmp_db2.sqlite").should == {
          tables: {
            added: [],
            removed: [],
            changed: [],
            unchanged: [
              {
                name: "foo",
                records: { counts: { added: 0, removed: 0, changed: 0, unchanged: 1 } }
              }
            ],
            counts: { added: 0, removed: 0, changed: 0, unchanged: 1}
          },
          records: { counts: { added: 0, removed: 0, changed: 0, unchanged: 1 } }
        }
      end

      it "should show a new table" do
        @db2.execute("CREATE TABLE bar (v1 text, v2 real)")
        Morph::Database.diffstat("tmp_db1.sqlite", "tmp_db2.sqlite").should == {
          tables: {
            added: [
              {
                name: "bar",
                records: {counts: {added: 0, removed: 0, changed: 0, unchanged: 0}}
              }
            ],
            removed: [],
            changed: [],
            unchanged: [
              {
                name: "foo",
                records: {counts: {added: 0, removed: 0, changed: 0, unchanged: 1}}
              }
            ],
            counts: {added: 1, removed: 0, changed: 0, unchanged: 1}
          },
          records: {counts: {added: 0, removed: 0, changed: 0, unchanged: 1}}
        }
      end

      it "should show a deleted table" do
        @db2.execute("DROP TABLE foo")
        Morph::Database.diffstat("tmp_db1.sqlite", "tmp_db2.sqlite").should == {
          tables: {
            added: [],
            removed: [
              {
                name: "foo",
                records: {counts: {added: 0, removed: 1, changed: 0, unchanged: 0}}
              }
            ],
            changed: [],
            unchanged: [],
            counts: {added: 0, removed: 1, changed: 0, unchanged: 0}
          },
          records: {counts: {added: 0, removed: 1, changed: 0, unchanged: 0}},
        }
      end

      it "should show an added and a deleted table" do
        @db2.execute("CREATE TABLE bar (v1 text, v2 real)")
        @db2.execute("DROP TABLE foo")
        Morph::Database.diffstat("tmp_db1.sqlite", "tmp_db2.sqlite").should == {
          tables: {
            added: [
              {
                name: "bar",
                records: {counts: {added: 0, removed: 0, changed: 0, unchanged: 0}}
              }
            ],
            removed: [
              {
                name: "foo",
                records: {counts: {added: 0, removed: 1, changed: 0, unchanged: 0}}
              }
            ],
            changed: [],
            unchanged: [],
            counts: {added: 1, removed: 1, changed: 0, unchanged: 0}
          },
          records: {counts: {added: 0, removed: 1, changed: 0, unchanged: 0}}
        }
      end

      it "should show a changed table (because of a schema change)" do
        @db2.execute("ALTER TABLE foo ADD v3 text")
        Morph::Database.diffstat("tmp_db1.sqlite", "tmp_db2.sqlite").should == {
          tables: {
            added: [],
            removed: [],
            changed: [
              {
                name: "foo",
                records: {counts: {added: 0, removed: 0, changed: 1, unchanged: 0}}
              }
            ],
            unchanged: [],
            counts: {added: 0, removed: 0, changed: 1, unchanged: 0}
          },
          records: {counts: {added: 0, removed: 0, changed: 1, unchanged: 0}}
        }
      end

      it "should show a new record on an unchanged table" do
        @db2.execute("INSERT INTO foo VALUES ('goodbye', 3.1)")
        Morph::Database.diffstat("tmp_db1.sqlite", "tmp_db2.sqlite").should == {
          tables: {
            added: [],
            removed: [],
            changed: [],
            unchanged: [
              {
                name: "foo",
                records: {counts: {added: 1, removed: 0, changed: 0, unchanged: 1}}
              }
            ],
            counts: {added: 0, removed: 0, changed: 0, unchanged: 1}
          },
          records: {counts: {added: 1, removed: 0, changed: 0, unchanged: 1}}
        }
      end

      it "should show a new record on a new table" do
        @db2.execute("CREATE TABLE bar (v1 text, v2 real)")
        @db2.execute("INSERT INTO bar VALUES ('goodbye', 3.1)")
        Morph::Database.diffstat("tmp_db1.sqlite", "tmp_db2.sqlite").should == {
          tables: {
            added: [
              name: "bar",
              records: {counts: {added: 1, removed: 0, changed: 0, unchanged: 0}}
            ],
            removed: [],
            changed: [],
            unchanged: [
              name: "foo",
              records: {counts: {added: 0, removed: 0, changed: 0, unchanged: 1}}
            ],
            counts: {added: 1, removed: 0, changed: 0, unchanged: 1}
          },
          records: {counts: {added: 1, removed: 0, changed: 0, unchanged: 1}}
        }
      end

      it "should show everything as added when there was no database to start with" do
        Morph::Database.diffstat("non_existent_file.sqlite", "tmp_db2.sqlite").should == {
          tables: {
            added: [
              {
                name: "foo",
                records: {counts: {added: 1, removed: 0, changed: 0, unchanged: 0}}
              }
            ],
            removed: [],
            changed: [],
            unchanged: [],
            counts: {added: 1, removed: 0, changed: 0, unchanged: 0}
          },
          records: {counts: {added: 1, removed: 0, changed: 0, unchanged: 0}}
        }
        FileUtils.rm("non_existent_file.sqlite")
      end

      it "should show no difference when comparing two non-existent databases" do
        Morph::Database.diffstat("non_existent_file1.sqlite", "non_existent_file2.sqlite").should == {
          tables: {
            added: [],
            removed: [],
            changed: [],
            unchanged: [],
            counts: {added: 0, removed: 0, changed: 0, unchanged: 0}
          },
          records: {counts: {added: 0, removed: 0, changed: 0, unchanged: 0}}
        }
        FileUtils.rm(["non_existent_file1.sqlite", "non_existent_file2.sqlite"])
      end
    end
  end
end
