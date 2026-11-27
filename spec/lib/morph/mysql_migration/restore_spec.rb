# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::MysqlMigration::Restore do
  subject(:restore) { described_class.new(admin, database: database) }

  let(:db_config) { ActiveRecord::Base.connection_db_config.configuration_hash }
  let(:admin) do
    Mysql2::Client.new(host: db_config[:host], port: db_config[:port], username: db_config[:username], password: db_config[:password], encoding: "utf8mb4")
  end
  let(:database) { "morph_migration_spec_#{Process.pid}" }

  after do
    admin.query("DROP DATABASE IF EXISTS `#{database}`")
    admin.close
  end

  def create_legacy_tables
    admin.query("CREATE DATABASE `#{database}`")
    admin.query("CREATE TABLE `#{database}`.`owners` (id int PRIMARY KEY, email varchar(255)) DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci")
    admin.query("CREATE TABLE `#{database}`.`webhooks` (id int PRIMARY KEY, url varchar(255), UNIQUE KEY u (url)) DEFAULT CHARSET=latin1")
  end

  describe "#create_database" do
    it "creates the database as utf8mb4_unicode_ci" do
      restore.create_database

      row = admin.query("SELECT DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = '#{database}'", as: :array).first
      expect(row).to eq %w[utf8mb4 utf8mb4_unicode_ci]
    end

    it "refuses a database that already has tables" do
      create_legacy_tables

      expect { restore.create_database }.to raise_error(/already has tables/)
    end
  end

  describe "#convert_empty_tables" do
    before { create_legacy_tables }

    it "converts tables of every legacy charset to utf8mb4_unicode_ci, columns included" do
      expect(restore.collation_problems).not_to be_empty

      expect(restore.convert_empty_tables).to contain_exactly("owners", "webhooks")

      expect(restore.collation_problems).to be_empty
    end

    it "then accepts four-byte characters that the old charset could not store" do
      restore.convert_empty_tables

      admin.query("INSERT INTO `#{database}`.`owners` VALUES (1, 'emoji \u{1F600}')")

      expect(admin.query("SELECT email FROM `#{database}`.`owners`", as: :array).first.first).to eq "emoji \u{1F600}"
    end

    it "refuses to convert tables that hold rows" do
      admin.query("INSERT INTO `#{database}`.`owners` VALUES (1, 'a@example.invalid')")

      expect { restore.convert_empty_tables }.to raise_error(/hold rows: owners/)
    end

    it "leaves a table that is already right alone" do
      restore.convert_empty_tables

      expect(restore.convert_empty_tables).to be_empty
    end
  end

  it "reports whether LOAD DATA LOCAL INFILE is switched on" do
    expect(restore.local_infile_enabled?).to be(true).or be(false)
  end
end
