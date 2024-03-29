# typed: strict
# frozen_string_literal: true

module Morph
  class Database
    extend T::Sig
    CORRUPT_DATABASE_EXCEPTIONS = T.let([
      SQLite3::NotADatabaseException,
      SQLite3::CorruptException,
      SQLite3::CantOpenException
    ].freeze, T::Array[T.class_of(SQLite3::Exception)])

    sig { params(data_path: String).void }
    def initialize(data_path)
      @data_path = data_path
    end

    sig { returns(String) }
    def self.sqlite_db_filename
      "data.sqlite"
    end

    sig { returns(String) }
    def self.sqlite_db_backup_filename
      "#{sqlite_db_filename}.backup"
    end

    sig { returns(String) }
    def self.sqlite_table_name
      "data"
    end

    sig { returns(String) }
    def sqlite_db_path
      File.join(@data_path, Database.sqlite_db_filename)
    end

    sig { returns(String) }
    def sqlite_db_backup_path
      File.join(@data_path, Database.sqlite_db_backup_filename)
    end

    sig { void }
    def backup
      return unless File.exist?(sqlite_db_path)

      FileUtils.cp(sqlite_db_path, sqlite_db_backup_path)
    end

    # The actual table names in the current db
    sig { returns(T::Array[String]) }
    def table_names
      q = sql_query_safe("select name from sqlite_master where type='table'")
      if q
        q = q.map { |h| h["name"] }
        # sqlite_sequence is a special system table (used with autoincrement)
        q.delete("sqlite_sequence")
        q
      else
        []
      end
    end

    sig { returns(T::Boolean) }
    def valid?
      # It's possible for a database to be malformed but just getting the table
      # names will work without error. So, getting a little sample data from
      # each table to really test things
      table_names.each { |table| first_ten_rows(table) }
      true
    rescue *CORRUPT_DATABASE_EXCEPTIONS
      false
    end

    # The table that should be listed first because it is the most important
    sig { returns(T.nilable(String)) }
    def first_table_name
      if table_names.include?(Database.sqlite_table_name)
        Database.sqlite_table_name
      else
        table_names.first
      end
    end

    sig { params(query: T.nilable(String), readonly: T::Boolean, block: T.proc.params(row: T::Hash[String, T.untyped]).void).void }
    def sql_query_streaming(query, readonly: true, &block)
      raise SQLite3::Exception, "No query specified" if query.blank?

      SQLite3::Database.new(
        sqlite_db_path,
        results_as_hash: true,
        type_translation: true,
        readonly: readonly
      ) do |db|
        # If database is busy wait 5s
        db.busy_timeout(5000)
        add_database_type_translations(db)
        # We're not doing "db.execute(query) do |row|" because there's a bug
        # in db.execute which loads the entire result set into memory before doing
        # the type translation. There's a commit
        # https://github.com/sparklemotion/sqlite3-ruby/commit/0a3f3bf7b6eea5ed4a765011b7cb2361ee414f77
        # which looks like it will fix this but, despite being over a year old, hasn't made
        # its way into an official release yet. So, in the meantime, just doing things
        # a slightly different way to avoid the problem.
        begin
          result = db.query(query)
          result.each do |row|
            block.call Database.clean_utf8_query_row(row)
          end
        ensure
          result&.close
        end
      end
    end

    # SUPER IMPORTANT: Only use this method if the result is small because
    # it keeps the whole thing in memory. Otherwise use sql_query_streaming
    sig { params(query: T.nilable(String), readonly: T::Boolean).returns(T::Array[T::Hash[String, T.untyped]]) }
    def sql_query(query, readonly: true)
      array = []
      sql_query_streaming(query, readonly: readonly) do |row|
        array << row
      end
      array
    end

    sig { params(row: T::Hash[String, T.untyped]).returns(T::Hash[String, T.untyped]) }
    def self.clean_utf8_query_row(row)
      result = {}
      row.each { |k, v| result[clean_utf8_string(k)] = clean_utf8_string(v) }
      result
    end

    # Removes bits of strings that are invalid UTF8
    # If it's not a string just passed through unchanged
    sig { params(string: T.untyped).returns(T.untyped) }
    def self.clean_utf8_string(string)
      if string.respond_to?(:encode)
        if string.valid_encoding?
          # Actually try converting to utf-8 and check if that works
          begin
            string.encode("utf-8")
          rescue Encoding::UndefinedConversionError
            convert_to_utf8_and_clean_binary_string(string)
          end
        else
          convert_to_utf8_and_clean_binary_string(string)
        end
      else
        string
      end
    end

    # This is what we use when we don't know what the encoding of the string
    # is. This assumes little about the string encoding and cleans the result
    # when converting to utf-8. Using this is a last resort when simple
    # conversions aren't working.
    sig { params(string: String).returns(String) }
    def self.convert_to_utf8_and_clean_binary_string(string)
      string.encode("UTF-8", "binary",
                    invalid: :replace, undef: :replace, replace: "")
    end

    sig { params(query: String, readonly: T::Boolean).returns(T.nilable(T::Array[T::Hash[String, T.untyped]])) }
    def sql_query_safe(query, readonly: true)
      sql_query(query, readonly: readonly)
    rescue *CORRUPT_DATABASE_EXCEPTIONS, SQLite3::SQLException
      nil
    end

    # Returns 0 if table doesn't exists (or there is some other problem)
    # TODO: table should really NOT be nillable
    sig { params(table: T.nilable(String)).returns(Integer) }
    def no_rows(table = table_names.first)
      q = sql_query_safe(%{select count(*) from "#{table}"})
      q ? T.must(q.first).values.first : 0
    rescue *CORRUPT_DATABASE_EXCEPTIONS
      0
    end

    sig { returns(Integer) }
    def sqlite_db_size
      if File.exist?(sqlite_db_path)
        File::Stat.new(sqlite_db_path).size
      else
        0
      end
    end

    sig { returns(T::Array[String]) }
    def table_names_safe
      table_names
    rescue *CORRUPT_DATABASE_EXCEPTIONS
      []
    end

    # Total number of records across all tables
    sig { returns(Integer) }
    def sqlite_total_rows
      table_names_safe.map { |t| no_rows(t) }.sum
    end

    sig { void }
    def clear
      FileUtils.rm_f sqlite_db_path
    end

    sig { params(content: String).void }
    def write_sqlite_database(content)
      FileUtils.mkdir_p @data_path
      File.binwrite(sqlite_db_path, content)
    end

    # TODO: table should really NOT be nillable
    sig { params(table: T.nilable(String)).returns(String) }
    def select_first_ten(table = table_names.first)
      %(select * from "#{table}" limit 10)
    end

    # TODO: table should really NOT be nillable
    sig { params(table: T.nilable(String)).returns(String) }
    def select_all(table = table_names.first)
      %(select * from "#{table}")
    end

    # TODO: table should really NOT be nillable
    sig { params(table: T.nilable(String)).returns(T::Array[T::Hash[String, String]]) }
    def first_ten_rows(table = table_names.first)
      r = sql_query_safe(select_first_ten(table))
      r || []
    end

    private

    # Add translators for problematic type conversions
    sig { params(db: SQLite3::Database).void }
    def add_database_type_translations(db)
      # Don't error on dates that are FixNum and that don't parse
      %w[date datetime].each do |type|
        db.translator.add_translator(type) do |t, v|
          case t.downcase
          when "date"
            Date.parse(v.to_s)
          when "datetime"
            DateTime.parse(v.to_s)
          end
        rescue ArgumentError
          v
        end
      end

      # Over the default translator also allows booleans stored as integers
      %w[bit bool boolean].each do |type|
        db.translator.add_translator(type) do |_t, v|
          v = v.to_s
          !(v.strip.gsub(/00+/, "0") == "0" ||
             v.downcase == "false" ||
             v.downcase == "f" ||
             v.downcase == "no" ||
             v.downcase == "n")
        end
      end
    end
  end
end
