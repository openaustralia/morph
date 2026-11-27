# typed: strict
# frozen_string_literal: true

module Morph
  module MysqlMigration
    # Settings for the MySQL migration tasks, read from the environment so no credential lives in code.
    # There are no defaults for the two servers: a task that is not told both refuses to start.
    class Config
      extend T::Sig

      DEFAULT_ARCHIVE_SLICE_ROWS = 5_000_000
      DEFAULT_DUMP_THREADS = 4

      sig { params(env: T::Hash[String, T.nilable(String)]).void }
      def initialize(env = ENV.to_h)
        @env = env
      end

      sig { returns(Connection) }
      def source
        Connection.from_url(required("MYSQL_MIGRATION_SOURCE_URL"))
      end

      # The source is not needed once the old server is stopped, so a task that only touches the target (the backfill,
      # the scrub) works without it. The check that they differ applies whenever a source is named.
      sig { returns(Connection) }
      def target
        Connection.from_url(required("MYSQL_MIGRATION_TARGET_URL")).tap do |target|
          raise "MYSQL_MIGRATION_SOURCE_URL and MYSQL_MIGRATION_TARGET_URL point at the same database" if @env.fetch("MYSQL_MIGRATION_SOURCE_URL", nil).present? && target.same_server_and_database?(source)
        end
      end

      # The filter the last dump used. Verification reads this rather than working the filter out again, because the
      # 30-day cutoff moves on while a dump, a restore and a verification run.
      sig { returns(String) }
      def where_clause_path
        File.join(report_dir, "log_lines_where.sql")
      end

      # Local directory for the filtered cutover dump
      sig { returns(String) }
      def dump_dir
        required("MYSQL_MIGRATION_DUMP_DIR")
      end

      sig { returns(String) }
      def report_dir
        @env.fetch("MYSQL_MIGRATION_REPORT_DIR", nil).presence || "tmp/mysql_migration"
      end

      sig { returns(Integer) }
      def threads
        integer("MYSQL_MIGRATION_THREADS", DEFAULT_DUMP_THREADS)
      end

      # Backfill is throttled by thread count (loadDump has no byte rate cap), so it has its own setting
      sig { returns(Integer) }
      def backfill_threads
        integer("MYSQL_MIGRATION_BACKFILL_THREADS", 1)
      end

      sig { returns(Integer) }
      def archive_slice_rows
        integer("MYSQL_MIGRATION_ARCHIVE_SLICE_ROWS", DEFAULT_ARCHIVE_SLICE_ROWS)
      end

      # Where the archive manifest is kept. It travels with the archive: copy it to the machine that runs the backfill.
      sig { returns(String) }
      def archive_manifest_path
        @env.fetch("MYSQL_MIGRATION_ARCHIVE_MANIFEST", nil).presence || File.join(report_dir, "log_lines_archive_manifest.json")
      end

      # The archive goes to S3. A local directory can stand in for it when practising on one machine, but
      # S3 is what the move uses.
      sig { returns(String) }
      def archive_base_url
        local = @env.fetch("MYSQL_MIGRATION_ARCHIVE_DIR", nil)
        local.present? ? File.expand_path(local) : s3_prefix
      end

      sig { returns(T::Boolean) }
      def local_archive?
        @env.fetch("MYSQL_MIGRATION_ARCHIVE_DIR", nil).present?
      end

      # Options passed straight to mysqlsh. Credentials come from the standard AWS environment variables
      # or the named profile, and are never read here.
      sig { returns(T::Hash[String, String]) }
      def s3_options
        return {} if local_archive?

        {
          "s3BucketName" => required("MYSQL_MIGRATION_S3_BUCKET"),
          "s3Region" => @env.fetch("MYSQL_MIGRATION_S3_REGION", nil),
          "s3Profile" => @env.fetch("MYSQL_MIGRATION_S3_PROFILE", nil),
          "s3EndpointOverride" => @env.fetch("MYSQL_MIGRATION_S3_ENDPOINT", nil)
        }.compact_blank.transform_values(&:to_s)
      end

      sig { returns(String) }
      def s3_prefix
        required("MYSQL_MIGRATION_S3_PREFIX").delete_prefix("/").delete_suffix("/")
      end

      # The scrub runs only where this is explicitly "true". Provisioning for the rehearsal server must set it.
      sig { returns(T::Boolean) }
      def rehearsal?
        @env.fetch("MORPH_REHEARSAL", nil) == "true"
      end

      sig { returns(T.nilable(String)) }
      def server_name
        @env.fetch("SERVER_NAME", nil)
      end

      sig { params(name: String).returns(String) }
      def required(name)
        value = @env.fetch(name, nil)
        raise "environment variable #{name} needs to be set" if value.blank?

        value
      end

      private

      sig { params(name: String, default: Integer).returns(Integer) }
      def integer(name, default)
        value = @env.fetch(name, nil)
        return default if value.blank?

        Integer(value, 10).tap { |i| raise "#{name} must be positive" unless i.positive? }
      end
    end
  end
end
