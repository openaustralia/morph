# typed: strict
# frozen_string_literal: true

require "fileutils"
require "json"

module Morph
  module MysqlMigration
    class VerificationFailed < StandardError
      extend T::Sig

      sig { returns(T::Array[String]) }
      attr_reader :differences

      sig { params(differences: T::Array[String]).void }
      def initialize(differences)
        @differences = differences
        super("verification found #{differences.size} difference(s)")
      end
    end

    # The migration steps behind the mysql_migration rake tasks. Each records a report with its elapsed time.
    #
    # Everything here runs on the new (rehearsal) server, which has MySQL Shell 8.4 and Ruby 3.4, and reaches the
    # old server's MySQL through MYSQL_MIGRATION_SOURCE_URL (an SSH tunnel). Nothing writes to the source.
    class Steps
      extend T::Sig

      ShellFactory = T.type_alias { T.proc.params(connection: Connection).returns(T.untyped) }

      sig { params(config: Config, shell_factory: ShellFactory).void }
      def initialize(config: Config.new, shell_factory: ->(connection) { Shell.new(connection) })
        @config = config
        @shell_factory = shell_factory
      end

      # Runs MySQL Shell's upgrade checker for 8.4 against the source and fails on problems in the data.
      # This is a dump and restore into a fresh server, not an in-place upgrade, so errors about the source
      # server's own variables (such as default_authentication_plugin, which is always an error on 5.7) do not
      # block it: they are recorded, with the checks that could not run without the server's configuration file.
      sig { void }
      def check_source
        report = new_report("check_source")
        report.measure do
          shell = shell_for(@config.source)
          output = shell.run(shell.upgrade_check_script)
          checks = JSON.parse(output[/\{.*\}/m].to_s).fetch("checksPerformed", [])
          problems = checks.flat_map { |check| check.fetch("detectedProblems", []).map { |problem| problem.merge("check" => check["id"]) } }
          errors = problems.select { |problem| problem["level"] == "Error" }
          blocking = errors.reject { |problem| problem["dbObjectType"] == "SystemVariable" }
          report["errors_in_server_variables"] = errors - blocking
          report["blocking_errors"] = blocking
          report["warning_count"] = problems.count { |problem| problem["level"] == "Warning" }
          report["checks_not_run"] = checks.select { |check| check["status"] == "CONFIGURATION_ERROR" }.pluck("id")
          raise "the upgrade checker found #{blocking.size} error(s) in the data for MySQL 8.4" if blocking.any?
        end
      end

      # The cutover dump: every table, with log_lines cut down to the retained rows
      sig { params(dry_run: T::Boolean).void }
      def dump(dry_run: false)
        report = new_report("dump")
        report.measure do
          source = @config.source
          client = source.client
          retained = RetainedLogLines.new(client)
          summary = retained.summary
          report["retention"] = summary
          report["where_clause_file"] = save_where_clause(retained.where_clause)
          report["dry_run"] = dry_run
          shell = shell_for(source)
          shell.run(shell.dump_script(
                      schema: source.database, tables: table_names(client, source.database),
                      output_url: File.expand_path(@config.dump_dir), where: { "log_lines" => retained.where_clause },
                      threads: @config.threads, consistent: true, dry_run: dry_run
                    ))
        end
      end

      # Archives log_lines to S3 in id-range slices, skipping slices already in the manifest, so it can be stopped
      # and started again. The archive is immutable data, so it is taken without the global read lock.
      sig { params(dry_run: T::Boolean).void }
      def archive_log_lines(dry_run: false)
        report = new_report("archive_log_lines")
        report.measure do
          source = @config.source
          manifest = ArchiveManifest.new(@config.archive_manifest_path)
          min_id, max_id = source.client.query("SELECT COALESCE(MIN(id), 0), COALESCE(MAX(id), 0) FROM log_lines", as: :array).first.map(&:to_i)
          pending = manifest.pending_slices(min_id: min_id, max_id: max_id, slice_rows: @config.archive_slice_rows)
          report["min_id"] = min_id
          report["max_id"] = max_id
          report["slices_already_done"] = manifest.slices.size
          report["slices_pending"] = pending.size
          shell = shell_for(source)
          # MySQL Shell creates one directory level, so a local archive needs its parent first. S3 has no directories.
          FileUtils.mkdir_p(@config.archive_base_url) if @config.local_archive?
          pending.each do |slice|
            shell.run(shell.dump_script(
                        schema: source.database, tables: ["log_lines"], output_url: "#{@config.archive_base_url}/#{slice.name}",
                        where: { "log_lines" => "id BETWEEN #{slice.from_id} AND #{slice.to_id}" },
                        threads: @config.threads, consistent: false, s3_options: @config.s3_options, dry_run: dry_run
                      ))
            manifest.complete(slice) unless dry_run
          end
        end
      end

      # Restores the cutover dump into an empty database on MySQL 8.4 with utf8mb4_unicode_ci: create the database,
      # load the DDL, convert the still-empty tables, then load the data.
      sig { params(dry_run: T::Boolean).void }
      def restore(dry_run: false)
        report = new_report("restore")
        report.measure do
          target = @config.target
          admin = target.client(database: nil)
          restorer = Restore.new(admin, database: target.database)
          report["local_infile_enabled"] = restorer.local_infile_enabled?
          warn "local_infile is off on the target: loadDump needs it on" unless report.data["local_infile_enabled"]
          shell = shell_for(target)
          restorer.create_database unless dry_run
          shell.run(load_script(shell, target, load_ddl: true, load_data: false, dry_run: dry_run))
          report["converted_tables"] = restorer.convert_empty_tables unless dry_run
          shell.run(load_script(shell, target, load_ddl: false, load_data: true, dry_run: dry_run))
          unless dry_run
            problems = restorer.collation_problems
            report["collation_problems"] = problems
            raise "restored database is not utf8mb4_unicode_ci throughout: #{problems.first(5).join('; ')}" if problems.any?
          end
        end
      end

      # Loads the archived log_lines into the existing table, one slice at a time, with few threads.
      # Rows already present from the cutover dump are replaced by identical rows. Progress files let it resume.
      sig { params(dry_run: T::Boolean).void }
      def backfill_log_lines(dry_run: false)
        report = new_report("backfill_log_lines")
        report.measure do
          manifest = ArchiveManifest.new(@config.archive_manifest_path)
          raise "no archive manifest at #{@config.archive_manifest_path}: copy it from where the archive was made" if manifest.slices.empty?

          target = @config.target
          shell = shell_for(target)
          report["slices"] = manifest.slices.size
          manifest.slices.each do |slice|
            shell.run(shell.load_script(
                        input_url: "#{@config.archive_base_url}/#{slice.name}", target_schema: target.database,
                        threads: @config.backfill_threads, progress_file: progress_file("backfill-#{slice.name}"),
                        load_ddl: false, load_data: true, s3_options: @config.s3_options, dry_run: dry_run
                      ))
          end
        end
      end

      # Scrubs the restored copy. Refuses unless this is a rehearsal environment.
      sig { void }
      def scrub
        report = new_report("scrub")
        report.measure do
          scrubber = Scrub.new(config: @config)
          scrubber.check_allowed!
          report["rows_changed"] = scrubber.run!(@config.target.client)
        end
      end

      # Compares source and target, then records the elapsed time. VERIFY_SCOPE=full compares the whole of log_lines
      # (after the backfill); the default compares the retained rows, using the filter the dump recorded, after the cutover
      # load. Run it before the scrub.
      sig { params(scope: String).returns(T::Array[String]) }
      def verify(scope: "retained")
        report = new_report("verify")
        differences = T.let([], T::Array[String])
        report.measure do
          raise ArgumentError, "scope must be retained or full" unless %w[retained full].include?(scope)

          source = @config.source
          target = @config.target
          source_client = source.client
          target_client = target.client
          where = scope == "retained" ? saved_where_clause : nil
          source_snapshot = Verification.new(source_client, database: source.database, log_lines_where: where).snapshot
          target_verification = Verification.new(target_client, database: target.database)
          target_snapshot = target_verification.snapshot
          report["scope"] = scope
          report["source"] = source_snapshot
          report["target"] = target_snapshot
          differences.concat(Verification.differences(source_snapshot, target_snapshot))
          differences.concat(target_verification.auto_increment_problems(source_snapshot))
          differences.concat(Restore.new(target_client, database: target.database).collation_problems)
          report["differences"] = differences
          raise VerificationFailed, differences if differences.any?
        end
        differences
      end

      # CHECKSUM TABLE of the target. With a baseline file, lists tables that changed since it was taken
      # (a re-run of the backfill should change nothing).
      sig { params(baseline_path: T.nilable(String)).returns(T::Array[String]) }
      def checksums(baseline_path: nil)
        report = new_report("checksums")
        changed = T.let([], T::Array[String])
        report.measure do
          target = @config.target
          current = Verification.new(target.client, database: target.database).table_checksums
          report["checksums"] = current
          if baseline_path
            baseline = JSON.parse(File.read(baseline_path)).fetch("checksums")
            changed.concat(current.reject { |t, sum| baseline[t] == sum }.keys)
            report["changed_since_baseline"] = changed
          end
        end
        changed
      end

      private

      sig { params(name: String).returns(Report) }
      def new_report(name)
        Report.new(name, dir: @config.report_dir)
      end

      sig { params(connection: Connection).returns(T.untyped) }
      def shell_for(connection)
        @shell_factory.call(connection)
      end

      sig { params(shell: T.untyped, target: Connection, load_ddl: T::Boolean, load_data: T::Boolean, dry_run: T::Boolean).returns(String) }
      def load_script(shell, target, load_ddl:, load_data:, dry_run:)
        shell.load_script(
          input_url: File.expand_path(@config.dump_dir), target_schema: target.database, threads: @config.threads,
          progress_file: progress_file(load_ddl ? "restore-ddl" : "restore-data"),
          load_ddl: load_ddl, load_data: load_data, dry_run: dry_run
        )
      end

      sig { params(name: String).returns(String) }
      def progress_file(name)
        FileUtils.mkdir_p(@config.report_dir)
        File.expand_path(File.join(@config.report_dir, "load-progress-#{name}.json"))
      end

      sig { params(client: T.untyped, database: String).returns(T::Array[String]) }
      def table_names(client, database)
        client.query("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = '#{client.escape(database)}' AND TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME",
                     as: :array).map(&:first)
      end

      # The filter can run to hundreds of kilobytes, so it goes to a file rather than into the report. Verification
      # reads the same file, and it is kept with a timestamp as well for the record.
      sig { params(clause: String).returns(String) }
      def save_where_clause(clause)
        FileUtils.mkdir_p(@config.report_dir)
        File.write("#{@config.where_clause_path}.tmp", "#{clause}\n")
        File.rename("#{@config.where_clause_path}.tmp", @config.where_clause_path)
        FileUtils.cp(@config.where_clause_path, @config.where_clause_path.sub(/\.sql\z/, "-#{Time.now.utc.strftime('%Y%m%dT%H%M%SZ')}.sql"))
        @config.where_clause_path
      end

      sig { returns(String) }
      def saved_where_clause
        path = @config.where_clause_path
        raise "no #{path}: run mysql_migration:dump first, or verify with VERIFY_SCOPE=full" unless File.exist?(path)

        File.read(path).strip
      end
    end
  end
end
