require 'spec_helper'

describe Morph::Database do
  before(:each) do
    FileUtils::rm_f(["tmp_db1.sqlite", "tmp_db2.sqlite"])
    # Create an sqlite database
    @db1 = SQLite3::Database.new("tmp_db1.sqlite", results_as_hash: true, type_translation: true)
    @db1.execute("CREATE TABLE foo (v1 text, v2 real);")
    @db1.execute("INSERT INTO foo VALUES ('hello', 2.3)")
    # Make an identical version
    FileUtils::cp("tmp_db1.sqlite", "tmp_db2.sqlite")
    @db2 = SQLite3::Database.new("tmp_db2.sqlite", results_as_hash: true, type_translation: true)
  end
  after(:each) { FileUtils::rm(["tmp_db1.sqlite", "tmp_db2.sqlite"]) }

  describe ".diffstat_table" do
    it "should show no change for two identical sqlite databases" do
      Morph::Database.diffstat_table("foo", @db1, @db2).should == {added: 0, removed: 0, changed: 0}
    end

    it "should show a new record" do
      @db2.execute("INSERT INTO foo VALUES ('goodbye', 3.1)")
      Morph::Database.diffstat_table("foo", @db1, @db2).should == {added: 1, removed: 0, changed: 0}
    end

    it "should show a deleted record" do
      @db2.execute("DELETE FROM foo")
      Morph::Database.diffstat_table("foo", @db1, @db2).should == {added: 0, removed: 1, changed: 0}
    end
  end
end
