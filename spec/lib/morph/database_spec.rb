# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::Database do
  describe ".clean_utf8_string" do
    it { expect(described_class.clean_utf8_string("This is valid UTF8")).to eq "This is valid UTF8" }
    it { expect(described_class.clean_utf8_string("Rodolfo Moisés Castañón Fuentes")).to eq "Rodolfo Moisés Castañón Fuentes" }
    it { expect(described_class.clean_utf8_string("foo\xA2bar")).to eq "foobar" }
    it { expect(described_class.clean_utf8_string("Casta\xC3\xB1\xC3\xB3n")).to eq "Castañón" }

    it do
      # This ascii-8bit string can't be converted to utf-8
      string = +"\xC2Andrea \xC2Belluzzi"
      string.force_encoding("ASCII-8BIT")
      expect(described_class.clean_utf8_string(string)).to eq "Andrea Belluzzi"
    end
  end

  describe "#backup" do
    it "backups the database file" do
      # Create a fake database file
      File.write("data.sqlite", "This is a fake sqlite file")
      d = described_class.new(".")
      d.backup
      expect(File.read("data.sqlite.backup")).to eq "This is a fake sqlite file"
      FileUtils.rm(["data.sqlite", "data.sqlite.backup"])
    end

    it "does not do anything if the database file isn't there" do
      d = described_class.new(".")
      d.backup
    end
  end

  describe "#sql_query" do
    let(:database) { described_class.new(".") }

    it { expect { database.sql_query("") }.to raise_error SQLite3::Exception, "No query specified" }
    it { expect { database.sql_query(nil) }.to raise_error SQLite3::Exception, "No query specified" }

    describe "type conversions" do
      it "allows booleans to be stored as integers" do
        database = described_class.new(File.join(RSpec.configuration.fixture_path, "files", "sqlite_databases", "boolean_stored_as_integer"))
        expect(database.sql_query("SELECT * FROM data")).to eql [{ "some_column" => false }, { "some_column" => true }]
      end

      it "returns the raw value when encountering a date stored as an unparseable fixnum" do
        database = described_class.new(File.join(RSpec.configuration.fixture_path, "files", "sqlite_databases", "unparseable_date_stored_as_fixnum"))
        expect(database.sql_query("SELECT * FROM data")).to eql [{ "some_column" => 148392075227 }]
      end

      it "converts datetime field into DateTime object" do
        database = described_class.new(File.join(RSpec.configuration.fixture_path, "files", "sqlite_databases", "datetime_field"))
        expect(database.sql_query("SELECT * FROM data")).to eql [{ "some_column" => DateTime.new(2017, 1, 2, 3, 4, 56.789012) }]
      end
    end
  end
end
