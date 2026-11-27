# typed: false
# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

# Each step needs the same stand-ins for the two servers, mysqlsh and the filesystem
# rubocop:disable RSpec/MultipleMemoizedHelpers
describe Morph::MysqlMigration::Steps do
  # Stands in for a server: the specs run in a transaction, so every client is the one test connection
  let(:connection_class) do
    Class.new(Morph::MysqlMigration::Connection) do
      def client(database: nil) # rubocop:disable Lint/UnusedMethodArgument
        ActiveRecord::Base.connection.raw_connection
      end
    end
  end

  # Records the scripts it is given instead of running mysqlsh
  let(:recording_shell_class) do
    Class.new(Morph::MysqlMigration::Shell) do
      attr_reader :scripts
      attr_accessor :output

      def run(script_body)
        (@scripts ||= []) << script_body
        output || "#{Morph::MysqlMigration::Shell::OK_MARKER}\n"
      end
    end
  end

  let(:dir) { Dir.mktmpdir }
  let(:database) { ActiveRecord::Base.connection.current_database }
  let(:env) do
    {
      "MYSQL_MIGRATION_SOURCE_URL" => "mysql2://u:p@old.example.invalid:3306/#{database}",
      "MYSQL_MIGRATION_TARGET_URL" => "mysql2://u:p@new.example.invalid:3306/#{database}",
      "MYSQL_MIGRATION_DUMP_DIR" => File.join(dir, "dump"),
      "MYSQL_MIGRATION_REPORT_DIR" => File.join(dir, "reports"),
      "MYSQL_MIGRATION_ARCHIVE_MANIFEST" => File.join(dir, "manifest.json"),
      "MYSQL_MIGRATION_S3_BUCKET" => "example-archive",
      "MYSQL_MIGRATION_S3_PREFIX" => "archive/log_lines",
      "MYSQL_MIGRATION_ARCHIVE_SLICE_ROWS" => "2"
    }
  end
  let(:config) { Morph::MysqlMigration::Config.new(env) }
  let(:shell) { recording_shell_class.new(Morph::MysqlMigration::Connection.from_url(env["MYSQL_MIGRATION_SOURCE_URL"])) }
  let(:steps) { described_class.new(config: config, shell_factory: ->(_connection) { shell }) }

  def report(name)
    path = Dir[File.join(dir, "reports", "#{name}-*.json")].first
    path && JSON.parse(File.read(path))
  end

  before do
    allow(config).to receive_messages(source: connection_class.from_url(env["MYSQL_MIGRATION_SOURCE_URL"]), target: connection_class.from_url(env["MYSQL_MIGRATION_TARGET_URL"]))
    allow($stdout).to receive(:puts)
  end

  after { FileUtils.remove_entry(dir) }

  describe "#check_source" do
    def checker_output(*checks)
      "#{JSON.generate({ 'errorCount' => 9, 'checksPerformed' => checks })}\n#{Morph::MysqlMigration::Shell::OK_MARKER}"
    end

    let(:variable_error) do
      { "id" => "authMethodUsage", "status" => "OK",
        "detectedProblems" => [{ "level" => "Error", "dbObjectType" => "SystemVariable", "dbObject" => "default_authentication_plugin" }] }
    end
    let(:not_run) { { "id" => "sysvarAllowedValues", "status" => "CONFIGURATION_ERROR" } }

    it "passes, recording rather than failing on errors in the source server's own variables" do
      shell.output = checker_output(variable_error, not_run,
                                    { "id" => "reservedKeywords", "detectedProblems" => [{ "level" => "Warning", "dbObjectType" => "Column" }] })

      expect { steps.check_source }.not_to raise_error
      expect(report("check_source")).to include("outcome" => "succeeded", "warning_count" => 1, "checks_not_run" => ["sysvarAllowedValues"])
      expect(report("check_source")["errors_in_server_variables"].size).to eq 1
    end

    it "fails when it finds an error in the data" do
      table_error = { "id" => "oldTemporal", "detectedProblems" => [{ "level" => "Error", "dbObjectType" => "Column", "dbObject" => "db.t.c" }] }
      shell.output = checker_output(variable_error, table_error)

      expect { steps.check_source }.to raise_error(/1 error\(s\) in the data/)
      expect(report("check_source")).to include("outcome" => "failed")
    end
  end

  describe "#dump" do
    before do
      run = create(:run, created_at: 1.day.ago)
      create(:log_line, run: run)
    end

    it "dumps every table with the retained filter on log_lines, and records it" do
      steps.dump

      script = shell.scripts.first
      expect(script).to include("util.dumpTables", '"consistent":true', "owners", "log_lines")
      expect(script).to match(/"#{database}\.log_lines":"run_id IS NULL OR run_id >= \d+"/)
      expect(report("dump")).to include("outcome" => "succeeded")
      expect(report("dump")["retention"]).to include("expected_row_count" => 1)
      expect(File.read(report("dump")["where_clause_file"])).to start_with("run_id IS NULL")
    end

    it "passes a dry run through to mysqlsh" do
      steps.dump(dry_run: true)

      expect(shell.scripts.first).to include('"dryRun":true')
    end

    it "records the elapsed time even when mysqlsh fails" do
      allow(shell).to receive(:run).and_raise("mysqlsh failed")

      expect { steps.dump }.to raise_error("mysqlsh failed")
      expect(report("dump")).to include("outcome" => "failed", "error" => "mysqlsh failed")
      expect(report("dump")["elapsed_seconds"]).to be_a(Numeric)
    end
  end

  describe "#archive_log_lines" do
    before do
      run = create(:run)
      5.times { create(:log_line, run: run) }
    end

    it "dumps each id slice to its own S3 prefix without the global read lock, and records the slices" do
      steps.archive_log_lines

      expect(shell.scripts.size).to eq 3
      expect(shell.scripts.first).to include('"archive/log_lines/ids-', '"consistent":false', '"s3BucketName":"example-archive"')
      manifest = Morph::MysqlMigration::ArchiveManifest.new(env["MYSQL_MIGRATION_ARCHIVE_MANIFEST"])
      expect(manifest.covered_up_to_id).to eq LogLine.maximum(:id)
    end

    it "resumes after an interruption, dumping only the slices not yet complete" do
      calls = 0
      allow(shell).to receive(:run) do
        calls += 1
        raise "connection lost" if calls == 2

        "#{Morph::MysqlMigration::Shell::OK_MARKER}\n"
      end

      expect { steps.archive_log_lines }.to raise_error("connection lost")
      expect(Morph::MysqlMigration::ArchiveManifest.new(env["MYSQL_MIGRATION_ARCHIVE_MANIFEST"]).slices.size).to eq 1

      calls = 100
      steps.archive_log_lines

      expect(Morph::MysqlMigration::ArchiveManifest.new(env["MYSQL_MIGRATION_ARCHIVE_MANIFEST"]).slices.size).to eq 3
      expect(report("archive_log_lines")).to include("slices_already_done" => 1, "slices_pending" => 2)
    end

    it "does not record slices from a dry run" do
      steps.archive_log_lines(dry_run: true)

      expect(File.exist?(env["MYSQL_MIGRATION_ARCHIVE_MANIFEST"])).to be false
    end

    it "does nothing when everything is already archived" do
      steps.archive_log_lines
      shell.scripts.clear

      steps.archive_log_lines

      expect(shell.scripts).to be_empty
    end
  end

  describe "#restore" do
    it "loads the DDL, then the data, into the target schema on a dry run" do
      steps.restore(dry_run: true)

      ddl, data = shell.scripts
      expect(ddl).to include('"loadDdl":true', '"loadData":false', '"ignoreVersion":true', "\"schema\":\"#{database}\"")
      expect(data).to include('"loadDdl":false', '"loadData":true', '"dryRun":true')
      expect(report("restore")).to include("outcome" => "succeeded")
    end
  end

  describe "#backfill_log_lines" do
    it "refuses without a manifest" do
      expect { steps.backfill_log_lines }.to raise_error(/no archive manifest/)
    end

    it "loads each archived slice without DDL, with few threads, through a progress file" do
      manifest = Morph::MysqlMigration::ArchiveManifest.new(env["MYSQL_MIGRATION_ARCHIVE_MANIFEST"])
      manifest.pending_slices(min_id: 1, max_id: 4, slice_rows: 2).each { |s| manifest.complete(s) }

      steps.backfill_log_lines

      expect(shell.scripts.size).to eq 2
      expect(shell.scripts.first).to include('"loadDdl":false', '"threads":1', "archive/log_lines/ids-000000000001-000000000002", "load-progress-backfill-ids-000000000001")
    end
  end

  describe "#scrub" do
    let!(:owner) { create(:user, email: "someone@example.com", access_token: "token-placeholder") }

    it "refuses outside a rehearsal environment and says so in the report" do
      expect { steps.scrub }.to raise_error(Morph::MysqlMigration::ScrubRefused)

      expect(report("scrub")).to include("outcome" => "failed")
      expect(owner.reload.access_token).to eq "token-placeholder"
    end

    context "when the environment is a rehearsal one" do
      let(:env) { super().merge("MORPH_REHEARSAL" => "true") }

      it "scrubs and records what it changed" do
        steps.scrub

        expect(owner.reload.email).to eq "owner-#{owner.id}@example.invalid"
        expect(report("scrub")["rows_changed"]).to include("owners" => 1)
      end
    end
  end

  describe "#verify" do
    before { create(:user) }

    it "records elapsed time, and fails because the test database is not utf8mb4_unicode_ci" do
      expect { steps.verify }.to raise_error(Morph::MysqlMigration::VerificationFailed) { |error|
        expect(error.differences).to all(include("is utf8"))
      }

      recorded = report("verify")
      expect(recorded["elapsed_seconds"]).to be_a(Numeric)
      expect(recorded["differences"]).not_to be_empty
    end

    it "compares the whole of log_lines after the backfill" do
      expect { steps.verify(scope: "full") }.to raise_error(Morph::MysqlMigration::VerificationFailed)

      expect(report("verify")["scope"]).to eq "full"
    end

    it "rejects an unknown scope" do
      expect { steps.verify(scope: "some") }.to raise_error(ArgumentError)
    end
  end

  describe "#checksums" do
    it "lists tables that changed since a baseline" do
      steps.checksums
      baseline = Dir[File.join(dir, "reports", "checksums-*.json")].first
      create(:user)

      expect(steps.checksums(baseline_path: baseline)).to include("owners")
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
