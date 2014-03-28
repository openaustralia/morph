require 'spec_helper'

describe Morph::Database do
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

    it "should be able to handle a large number of records" do
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

    describe ".diffstat" do
      it "should show that nothing has changed" do
        Morph::Database.diffstat(@db1, @db2).should == {
          records: {added: 0, removed: 0, changed: 0},
          tables:  {added: 0, removed: 0, changed: 0}
        }
      end

      it "should show a new table" do
        @db2.execute("CREATE TABLE bar (v1 text, v2 real)")
        Morph::Database.diffstat(@db1, @db2).should == {
          records: {added: 0, removed: 0, changed: 0},
          tables:  {added: 1, removed: 0, changed: 0}
        }
      end

      it "should show a deleted table" do
        @db2.execute("DROP TABLE foo")
        Morph::Database.diffstat(@db1, @db2).should == {
          records: {added: 0, removed: 1, changed: 0},
          tables:  {added: 0, removed: 1, changed: 0}
        }
      end

      it "should show an added and a deleted table" do
        @db2.execute("CREATE TABLE bar (v1 text, v2 real)")
        @db2.execute("DROP TABLE foo")
        Morph::Database.diffstat(@db1, @db2).should == {
          records: {added: 0, removed: 1, changed: 0},
          tables:  {added: 1, removed: 1, changed: 0}
        }
      end

      it "should show a changed table (because of a schema change)" do
        @db2.execute("ALTER TABLE foo ADD v3 text")
        Morph::Database.diffstat(@db1, @db2).should == {
          records: {added: 0, removed: 0, changed: 1},
          tables:  {added: 0, removed: 0, changed: 1}
        }
      end

      it "should show a new record on an unchanged table" do
        @db2.execute("INSERT INTO foo VALUES ('goodbye', 3.1)")
        Morph::Database.diffstat(@db1, @db2).should == {
          records: {added: 1, removed: 0, changed: 0},
          tables:  {added: 0, removed: 0, changed: 0}
        }
      end

      it "should show a new record on a new table" do
        @db2.execute("CREATE TABLE bar (v1 text, v2 real)")
        @db2.execute("INSERT INTO bar VALUES ('goodbye', 3.1)")
        Morph::Database.diffstat(@db1, @db2).should == {
          records: {added: 1, removed: 0, changed: 0},
          tables:  {added: 1, removed: 0, changed: 0}
        }
      end
    end
  end
end
