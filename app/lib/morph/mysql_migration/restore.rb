# typed: strict
# frozen_string_literal: true

module Morph
  module MysqlMigration
    # The database-side steps of restoring into MySQL 8.4 with utf8mb4_unicode_ci (#1571, ADR 0003).
    #
    # loadDump recreates production's own DDL, which is a mix of utf8 and latin1 (#1494). The tables are converted
    # to utf8mb4 while they are still empty, which is instant and cannot truncate or garble anything, and the data
    # is loaded afterwards. The data files are always utf8mb4, so each value is converted once, on the way in.
    class Restore
      extend T::Sig

      CHARSET = "utf8mb4"
      COLLATION = Shell::UTF8MB4_COLLATION

      sig { params(client: T.untyped, database: String).void }
      def initialize(client, database:)
        @client = client
        @database = database
      end

      sig { void }
      def create_database
        raise "database #{@database} already has tables: restore only into an empty database" if tables.any?

        @client.query("CREATE DATABASE IF NOT EXISTS #{quote(@database)} CHARACTER SET #{CHARSET} COLLATE #{COLLATION}")
        @client.query("ALTER DATABASE #{quote(@database)} CHARACTER SET #{CHARSET} COLLATE #{COLLATION}")
      end

      sig { returns(T::Array[String]) }
      def tables
        @client.query("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = #{escape(@database)} ORDER BY TABLE_NAME",
                      as: :array).map(&:first)
      end

      # Converts every table that is not already utf8mb4_unicode_ci. Refuses if any table holds rows.
      sig { returns(T::Array[String]) }
      def convert_empty_tables
        non_empty = tables.reject { |t| @client.query("SELECT 1 FROM #{qualified(t)} LIMIT 1").none? }
        raise "refusing to convert tables that hold rows: #{non_empty.join(', ')}" if non_empty.any?

        @client.query("ALTER DATABASE #{quote(@database)} CHARACTER SET #{CHARSET} COLLATE #{COLLATION}")
        converted = collation_by_table.reject { |_, collation| collation == COLLATION }.keys
        converted.each do |t|
          @client.query("ALTER TABLE #{qualified(t)} CONVERT TO CHARACTER SET #{CHARSET} COLLATE #{COLLATION}")
        end
        converted
      end

      # Table and column collations that are not utf8mb4_unicode_ci. An empty list means the restore is as decided.
      sig { returns(T::Array[String]) }
      def collation_problems
        problems = collation_by_table.reject { |_, collation| collation == COLLATION }.map { |t, c| "table #{t} is #{c}" }
        columns = @client.query(<<~SQL.squish, as: :array)
          SELECT TABLE_NAME, COLUMN_NAME, COLLATION_NAME FROM information_schema.COLUMNS
          WHERE TABLE_SCHEMA = #{escape(@database)} AND COLLATION_NAME IS NOT NULL AND COLLATION_NAME <> '#{COLLATION}'
        SQL
        problems + columns.map { |t, c, collation| "column #{t}.#{c} is #{collation}" }
      end

      # loadDump needs LOAD DATA LOCAL INFILE on the target
      sig { returns(T::Boolean) }
      def local_infile_enabled?
        @client.query("SELECT @@GLOBAL.local_infile", as: :array).first.first.to_i == 1
      end

      private

      sig { returns(T::Hash[String, String]) }
      def collation_by_table
        @client.query("SELECT TABLE_NAME, TABLE_COLLATION FROM information_schema.TABLES WHERE TABLE_SCHEMA = #{escape(@database)} AND TABLE_TYPE = 'BASE TABLE'",
                      as: :array).to_h
      end

      sig { params(table: String).returns(String) }
      def qualified(table)
        "#{quote(@database)}.#{quote(table)}"
      end

      sig { params(name: String).returns(String) }
      def quote(name)
        "`#{name.gsub('`', '``')}`"
      end

      sig { params(value: String).returns(String) }
      def escape(value)
        "'#{@client.escape(value)}'"
      end
    end
  end
end
