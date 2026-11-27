# typed: strict
# frozen_string_literal: true

module Morph
  module MysqlMigration
    # Compares the source and the restored database table by table.
    #
    # CHECKSUM TABLE hashes stored bytes, so it differs on any table converted from utf8 or latin1 to utf8mb4 (#1571).
    # Instead each side hashes the values it returns to a utf8mb4 connection, which is the same on both sides whatever
    # the storage charset. Small tables are hashed whole. Large ones are hashed on a fixed sample of ids, because
    # reading every log_lines row would cost more than the rest of the check is worth.
    class Verification
      extend T::Sig

      FULL_HASH_LIMIT = 500_000
      SAMPLE_MODULUS = 100
      NULL_MARKER = "<NULL>"
      SKIPPED_TABLES = T.let(%w[ar_internal_metadata schema_migrations].freeze, T::Array[String])

      sig { params(client: T.untyped, database: String, log_lines_where: T.nilable(String)).void }
      def initialize(client, database:, log_lines_where: nil)
        @client = client
        @database = database
        @log_lines_where = log_lines_where
      end

      # => { "tables" => { "runs" => { "rows" => 12, "sampled" => false, "hash" => "123", "columns" => [...] } },
      #      "max_ids" => { "log_lines" => 99 } }
      sig { returns(T::Hash[String, T.untyped]) }
      def snapshot
        tables = table_names.index_with { |t| table_snapshot(t) }
        { "database" => @database, "taken_at" => Time.now.utc.iso8601, "tables" => tables, "max_ids" => max_ids(tables) }
      end

      # AUTO_INCREMENT on the target must be above the highest id on the source, or new rows would collide with
      # rows still to be backfilled (#1557).
      sig { params(source: T::Hash[String, T.untyped]).returns(T::Array[String]) }
      def auto_increment_problems(source)
        refresh_statistics
        source.fetch("max_ids").filter_map do |table, max_id|
          next_id = auto_increment(table)
          next if next_id && next_id > max_id

          "#{table}: AUTO_INCREMENT is #{next_id.inspect} but the source's highest id is #{max_id}"
        end
      end

      sig { params(source: T::Hash[String, T.untyped], target: T::Hash[String, T.untyped]).returns(T::Array[String]) }
      def self.differences(source, target)
        source_tables = source.fetch("tables")
        target_tables = target.fetch("tables")
        problems = (source_tables.keys - target_tables.keys).map { |t| "#{t}: missing from the target" }
        (target_tables.keys - source_tables.keys).each { |t| problems << "#{t}: not on the source" }
        (source_tables.keys & target_tables.keys).each do |t|
          problems.concat(table_differences(t, source_tables.fetch(t), target_tables.fetch(t)))
        end
        problems
      end

      sig { params(table: String, source: T::Hash[String, T.untyped], target: T::Hash[String, T.untyped]).returns(T::Array[String]) }
      def self.table_differences(table, source, target)
        problems = []
        problems << "#{table}: columns differ (#{source['columns'].inspect} against #{target['columns'].inspect})" if source["columns"] != target["columns"]
        problems << "#{table}: #{source['rows']} rows on the source, #{target['rows']} on the target" if source["rows"] != target["rows"]
        problems << "#{table}: value hash differs" if source["hash"] != target["hash"]
        problems
      end

      # CHECKSUM TABLE on one database before and after a re-load. Only meaningful target against target:
      # "a re-run changes nothing" (#1601).
      sig { returns(T::Hash[String, T.untyped]) }
      def table_checksums
        table_names.index_with do |t|
          @client.query("CHECKSUM TABLE #{quote(t)}", as: :array).first.last.to_s
        end
      end

      private

      sig { returns(T::Array[String]) }
      def table_names
        @client.query("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = #{escape(@database)} AND TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME",
                      as: :array).map(&:first) - SKIPPED_TABLES
      end

      sig { params(table: String).returns(T::Hash[String, T.untyped]) }
      def table_snapshot(table)
        columns = column_types(table)
        scope = scope_for(table)
        rows = @client.query("SELECT COUNT(*) FROM #{quote(table)} #{scope}", as: :array).first.first.to_i
        sampled = columns.key?("id") && rows > FULL_HASH_LIMIT
        # The filter is a chain of ORs, so it needs its own brackets before the sample condition is ANDed on
        filter = scope.sub(/\AWHERE /, "")
        conditions = if sampled
                       [filter.empty? ? nil : "(#{filter})", "MOD(id, #{SAMPLE_MODULUS}) = 0"].compact
                     else
                       [filter].reject(&:empty?)
                     end
        where = conditions.empty? ? "" : "WHERE #{conditions.join(' AND ')}"
        hash = @client.query("SELECT COALESCE(SUM(#{row_hash(columns)}), 0) FROM #{quote(table)} #{where}", as: :array).first.first.to_s
        { "rows" => rows, "sampled" => sampled, "hash" => hash, "columns" => columns.keys }
      end

      sig { params(table: String).returns(String) }
      def scope_for(table)
        return "" unless table == "log_lines" && @log_lines_where

        "WHERE #{@log_lines_where}"
      end

      sig { params(table: String).returns(T::Hash[String, String]) }
      def column_types(table)
        @client.query(<<~SQL.squish, as: :array).to_h
          SELECT COLUMN_NAME, DATA_TYPE FROM information_schema.COLUMNS
          WHERE TABLE_SCHEMA = #{escape(@database)} AND TABLE_NAME = #{escape(table)} ORDER BY ORDINAL_POSITION
        SQL
      end

      # A 32-bit slice of each row's MD5, summed. Summing rather than XOR-ing means identical rows do not cancel.
      sig { params(columns: T::Hash[String, String]).returns(String) }
      def row_hash(columns)
        expressions = columns.map { |name, type| value_expression(quote(name), type) }
        "CAST(CONV(SUBSTRING(MD5(CONCAT_WS('|', #{expressions.join(', ')})), 1, 8), 16, 10) AS UNSIGNED)"
      end

      # Every value becomes text in a form that is the same on MySQL 5.7 and 8.4, and every string column is
      # converted to one charset first so that columns of different collations can be joined without an error.
      sig { params(column: String, type: String).returns(String) }
      def value_expression(column, type)
        text = case type
               when "char", "varchar", "tinytext", "text", "mediumtext", "longtext", "enum", "set"
                 "CONVERT(#{column} USING utf8mb4)"
               when "datetime", "timestamp"
                 "DATE_FORMAT(#{column}, '%Y-%m-%d %H:%i:%s.%f')"
               when "float", "double"
                 "CAST(ROUND(#{column}, 4) AS DECIMAL(30, 4))"
               when "blob", "tinyblob", "mediumblob", "longblob", "binary", "varbinary"
                 "HEX(#{column})"
               else
                 "CAST(#{column} AS CHAR)"
               end
        "IFNULL(#{text}, '#{NULL_MARKER}')"
      end

      sig { params(tables: T::Hash[String, T.untyped]).returns(T::Hash[String, Integer]) }
      def max_ids(tables)
        tables.select { |_, s| s["columns"].include?("id") }.keys.index_with do |t|
          @client.query("SELECT COALESCE(MAX(id), 0) FROM #{quote(t)}", as: :array).first.first.to_i
        end
      end

      sig { params(table: String).returns(T.nilable(Integer)) }
      def auto_increment(table)
        @client.query("SELECT AUTO_INCREMENT FROM information_schema.TABLES WHERE TABLE_SCHEMA = #{escape(@database)} AND TABLE_NAME = #{escape(table)}",
                      as: :array).first&.first&.to_i
      end

      # MySQL 8 caches table statistics, which would show a stale AUTO_INCREMENT right after a load. 5.7 has no such variable.
      sig { void }
      def refresh_statistics
        @client.query("SET SESSION information_schema_stats_expiry = 0")
      rescue Mysql2::Error
        nil
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
