# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::MysqlMigration::Shell do
  subject(:shell) { described_class.new(connection) }

  let(:connection) { Morph::MysqlMigration::Connection.from_url("mysql2://scraping:hunter2-placeholder@db.example.invalid:3306/scraping_production") }

  # The options are written as JSON, so the script's own argument can be read back
  def options_of(script, call)
    JSON.parse(script[/#{Regexp.escape(call)}\(.*, (\{.*\})\);$/, 1])
  end

  describe "#dump_script" do
    let(:script) do
      shell.dump_script(
        schema: "scraping_production", tables: %w[owners log_lines], output_url: "/srv/dump", threads: 4, consistent: true,
        where: { "log_lines" => "run_id >= 100 OR run_id IN (1,2)" }
      )
    end

    it "dumps the named tables to the output directory with the filter on log_lines" do
      expect(script).to include('util.dumpTables("scraping_production", ["owners","log_lines"], "/srv/dump"')
      expect(options_of(script, "util.dumpTables")).to include(
        "where" => { "scraping_production.log_lines" => "run_id >= 100 OR run_id IN (1,2)" },
        "consistent" => true, "compression" => "zstd", "threads" => 4, "dryRun" => false
      )
    end

    it "ends with a marker so a script that stopped early is not taken for a finished one" do
      expect(script.lines.last.strip).to eq 'println("MYSQL_MIGRATION_OK");'
    end

    it "never contains the password" do
      expect(script).not_to include("hunter2")
    end

    it "adds the S3 settings for the archive, without the global read lock" do
      archive = shell.dump_script(
        schema: "scraping_production", tables: ["log_lines"], output_url: "archive/ids-1-10", threads: 2, consistent: false,
        where: { "log_lines" => "id BETWEEN 1 AND 10" }, s3_options: { "s3BucketName" => "example-archive", "s3Region" => "ap-southeast-2" }
      )

      expect(options_of(archive, "util.dumpTables")).to include("consistent" => false, "s3BucketName" => "example-archive", "s3Region" => "ap-southeast-2")
    end
  end

  describe "#load_script" do
    it "loads into the target schema, ignoring the version gap, resumable through a progress file" do
      script = shell.load_script(
        input_url: "/srv/dump", target_schema: "scraping_production", threads: 4, progress_file: "/srv/progress.json",
        load_ddl: true, load_data: false
      )

      expect(options_of(script, "util.loadDump")).to include(
        "schema" => "scraping_production", "ignoreVersion" => true, "loadDdl" => true, "loadData" => false,
        "progressFile" => "/srv/progress.json", "dryRun" => false
      )
    end

    it "loads the archive into the existing table without DDL" do
      script = shell.load_script(
        input_url: "archive/ids-1-10", target_schema: "scraping_production", threads: 1, progress_file: "/srv/p.json",
        load_ddl: false, load_data: true, s3_options: { "s3BucketName" => "example-archive" }
      )

      expect(options_of(script, "util.loadDump")).to include("loadDdl" => false, "loadData" => true, "threads" => 1, "s3BucketName" => "example-archive")
    end
  end

  it "builds an upgrade check for 8.4 that reports as JSON" do
    expect(shell.upgrade_check_script).to include('"targetVersion":"8.4.0"', '"outputFormat":"JSON"')
  end
end
