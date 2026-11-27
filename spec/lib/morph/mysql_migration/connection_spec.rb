# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::MysqlMigration::Connection do
  describe ".from_url" do
    it "reads the parts of a mysql2 URL, decoding the password" do
      connection = described_class.from_url("mysql2://scraping:p%40ss%2Fword@db.example.invalid:3307/scraping_production")

      expect(connection).to have_attributes(
        host: "db.example.invalid", port: 3307, username: "scraping", password: "p@ss/word", database: "scraping_production"
      )
    end

    it "keeps a literal plus sign in the password and decodes percent escapes" do
      connection = described_class.from_url("mysql2://scr%20aping:a+b%2Bc@localhost/db")

      expect(connection).to have_attributes(username: "scr aping", password: "a+b+c")
      expect(connection.shell_uri).to eq "scr%20aping@localhost:3306"
    end

    it "defaults the port" do
      expect(described_class.from_url("mysql2://u:p@localhost/db").port).to eq 3306
    end

    it "rejects a URL that is not a MySQL URL with a user and database" do
      expect { described_class.from_url("postgres://u:p@localhost/db") }.to raise_error(ArgumentError)
      expect { described_class.from_url("mysql2://localhost/db") }.to raise_error(ArgumentError)
      expect { described_class.from_url("mysql2://u:p@localhost") }.to raise_error(ArgumentError)
    end
  end

  describe "text that may reach a log or a command line" do
    subject(:connection) { described_class.from_url("mysql2://scraping:hunter2-placeholder@db.example.invalid:3307/scraping_production") }

    it "never includes the password" do
      expect(connection.to_s).not_to include("hunter2")
      expect(connection.shell_uri).not_to include("hunter2")
      expect(connection.shell_uri).to eq "scraping@db.example.invalid:3307"
    end
  end

  describe "#same_server_and_database?" do
    it "is true only for the same endpoint and database" do
      a = described_class.from_url("mysql2://u:p@localhost:3306/one")

      expect(a.same_server_and_database?(described_class.from_url("mysql2://x:y@localhost:3306/one"))).to be true
      expect(a.same_server_and_database?(described_class.from_url("mysql2://u:p@localhost:3306/two"))).to be false
      expect(a.same_server_and_database?(described_class.from_url("mysql2://u:p@other:3306/one"))).to be false
    end
  end
end
