# typed: strict
# frozen_string_literal: true

require "json"
require "open3"
require "tempfile"

module Morph
  module MysqlMigration
    # Builds and runs MySQL Shell (mysqlsh) scripts for the dump, the archive and the load.
    #
    # Options are written into a generated script file and passwords go to mysqlsh on stdin, so neither a
    # credential nor a very long where clause ever appears in a command line.
    # Option names come from the MySQL Shell 8.4 documentation and source and are checked by `dryRun` first.
    class Shell
      extend T::Sig

      OK_MARKER = "MYSQL_MIGRATION_OK"
      # A script that connects again (the upgrade checker does) asks for the password again; spare lines are ignored
      PASSWORD_PROMPTS = 3
      UTF8MB4_COLLATION = "utf8mb4_unicode_ci"

      sig { params(connection: Connection, executable: String).void }
      def initialize(connection, executable: "mysqlsh")
        @connection = connection
        @executable = executable
      end

      # The checker takes the connection as its first argument, so it connects again rather than reusing the session
      sig { returns(String) }
      def upgrade_check_script
        options = { "targetVersion" => "8.4.0", "outputFormat" => "JSON" }
        script(["util.checkForServerUpgrade(#{JSON.generate(@connection.shell_uri)}, #{JSON.generate(options)});"])
      end

      sig do
        params(
          schema: String, tables: T::Array[String], output_url: String, where: T::Hash[String, String],
          threads: Integer, consistent: T::Boolean, s3_options: T::Hash[String, String], dry_run: T::Boolean
        ).returns(String)
      end
      def dump_script(schema:, tables:, output_url:, where:, threads:, consistent:, s3_options: {}, dry_run: false)
        options = {
          "threads" => threads,
          "consistent" => consistent,
          "compression" => "zstd",
          "where" => where.transform_keys { |table| "#{schema}.#{table}" },
          "dryRun" => dry_run
        }.merge(s3_options)
        script(["util.dumpTables(#{JSON.generate(schema)}, #{JSON.generate(tables)}, #{JSON.generate(output_url)}, #{JSON.generate(options)});"])
      end

      sig do
        params(
          input_url: String, target_schema: String, threads: Integer, progress_file: String,
          load_ddl: T::Boolean, load_data: T::Boolean, s3_options: T::Hash[String, String], dry_run: T::Boolean
        ).returns(String)
      end
      def load_script(input_url:, target_schema:, threads:, progress_file:, load_ddl:, load_data:, s3_options: {}, dry_run: false)
        options = {
          "schema" => target_schema,
          "threads" => threads,
          "progressFile" => progress_file,
          "loadDdl" => load_ddl,
          "loadData" => load_data,
          # Non-consecutive major versions (5.7 to 8.4) are refused without this, after the upgrade check passes
          "ignoreVersion" => true,
          "dryRun" => dry_run
        }.merge(s3_options)
        script(["util.loadDump(#{JSON.generate(input_url)}, #{JSON.generate(options)});"])
      end

      # Runs a script file against the connection. Succeeds only if mysqlsh exits cleanly and the script reached its
      # end, because a script that fails part way must not be mistaken for a finished step.
      # :nocov:
      sig { params(script_body: String).returns(String) }
      def run(script_body)
        Tempfile.create(["mysql_migration", ".js"]) do |file|
          file.write(script_body)
          file.flush
          argv = [@executable, "--passwords-from-stdin", "--js", "--uri", @connection.shell_uri, "--file", file.path]
          stdout, stderr, status = Open3.capture3(*argv, stdin_data: "#{@connection.password}\n" * PASSWORD_PROMPTS)
          $stdout.puts stdout
          warn stderr unless stderr.empty?
          raise "mysqlsh failed (exit #{status.exitstatus}) against #{@connection}" unless status.success?
          raise "mysqlsh did not reach the end of the script against #{@connection}" unless stdout.include?(OK_MARKER)

          stdout
        end
      end
      # :nocov:

      private

      sig { params(statements: T::Array[String]).returns(String) }
      def script(statements)
        "#{(statements + ["println(#{JSON.generate(OK_MARKER)});"]).join("\n")}\n"
      end
    end
  end
end
