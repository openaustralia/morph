require 'spec_helper'

describe Morph::Database do
  before(:each) { FileUtils::rm_f(["tmp_db1.sqlite", "tmp_db2.sqlite"]) }
  after(:each) { FileUtils::rm(["tmp_db1.sqlite", "tmp_db2.sqlite"]) }

  describe ".diffstat_table" do
    it "should show no change for two identical sqlite databases" do
      # Create an sqlite database
      db1 = SQLite3::Database.new("tmp_db1.sqlite", results_as_hash: true, type_translation: true)
      db1.execute("CREATE TABLE foo (v1 text, v2 real);")
      db1.execute("INSERT INTO foo VALUES ('hello', 2.3)")
      # Make an identical version
      db2 = SQLite3::Database.new("tmp_db2.sqlite", results_as_hash: true, type_translation: true)
      db2.execute("CREATE TABLE foo (v1 text, v2 real);")
      db2.execute("INSERT INTO foo VALUES ('hello', 2.3)")
      # Now ask for the difference between the two
      Morph::Database.diffstat_table("foo", "tmp_db1.sqlite", "tmp_db2.sqlite").should == {added: 0, removed: 0, changed: 0}
    end

    it "should show a new record" do
      # Create an sqlite database
      db1 = SQLite3::Database.new("tmp_db1.sqlite", results_as_hash: true, type_translation: true)
      db1.execute("CREATE TABLE foo (v1 text, v2 real);")
      db1.execute("INSERT INTO foo VALUES ('hello', 2.3)")
      FileUtils::cp("tmp_db1.sqlite", "tmp_db2.sqlite")
      db2 = SQLite3::Database.new("tmp_db2.sqlite", results_as_hash: true, type_translation: true)
      db2.execute("INSERT INTO foo VALUES ('goodbye', 3.1)")
      # Now ask for the difference between the two
      Morph::Database.diffstat_table("foo", "tmp_db1.sqlite", "tmp_db2.sqlite").should == {added: 1, removed: 0, changed: 0}
    end
  end
end
