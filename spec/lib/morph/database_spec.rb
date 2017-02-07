require 'spec_helper'

describe Morph::Database do
  describe ".clean_utf8_string" do
    it { expect(Morph::Database.clean_utf8_string("This is valid UTF8")).to eq "This is valid UTF8" }
    it { expect(Morph::Database.clean_utf8_string("Rodolfo Moisés Castañón Fuentes")).to eq "Rodolfo Moisés Castañón Fuentes" }
    it { expect(Morph::Database.clean_utf8_string("foo\xA2bar")).to eq "foobar" }
    it { expect(Morph::Database.clean_utf8_string("Casta\xC3\xB1\xC3\xB3n")).to eq "Castañón" }
    it do
      # This ascii-8bit string can't be converted to utf-8
      string = "\xC2Andrea \xC2Belluzzi"
      string.force_encoding('ASCII-8BIT')
      expect( Morph::Database.clean_utf8_string(string)).to eq "Andrea Belluzzi"
    end
  end

  describe '#clear' do
    it "should not attempt to remove the file if it's not there" do
      expect(FileUtils).to_not receive(:rm)
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
      expect(File.read("data.sqlite.backup")).to eq "This is a fake sqlite file"
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

    describe "type conversions" do
      it "allows booleans to be stored as integers" do
        database = Morph::Database.new(RSpec.configuration.fixture_path + "/files/sqlite_databases/boolean_stored_as_integer/")
        expect(database.sql_query("SELECT * FROM data")).to eql [{"some_column" => false}, {"some_column" => true}]
      end

      it "returns the raw value when encountering a date stored as an unparseable fixnum" do
        database = Morph::Database.new(RSpec.configuration.fixture_path + "/files/sqlite_databases/unparseable_date_stored_as_fixnum/")
        expect(database.sql_query("SELECT * FROM data")).to eql [{"some_column" => 148392075227}]
      end
    end
  end
end
