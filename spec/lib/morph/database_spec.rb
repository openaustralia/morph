require 'spec_helper'

describe Morph::Database do
  describe ".diffstat" do
    it "should show no change for two identical sqlite databases" do
      FileUtils::rm(["tmp_db1.sqlite", "tmp_db2.sqlite"])
      # Create an sqlite database
      db1 = SQLite3::Database.new("tmp_db1.sqlite", results_as_hash: true, type_translation: true)
      db1.execute("CREATE TABLE foo (v1 text, v2 real);")
      db1.execute("INSERT INTO foo VALUES ('hello', 2.3)")
      # Make an identical version
      db2 = SQLite3::Database.new("tmp_db2.sqlite", results_as_hash: true, type_translation: true)
      db2.execute("CREATE TABLE foo (v1 text, v2 real);")
      db2.execute("INSERT INTO foo VALUES ('hello', 2.3)")
      # Now ask for the difference between the two
      Morph::Database.diffstat("tmp_db1.sqlite", "tmp_db2.sqlite").should == {added: 0, removed: 0, changed: 0}
    end
  end
end
