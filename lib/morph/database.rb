module Morph
  class Database
    attr_reader :scraper
    delegate :data_path, to: :scraper

    def initialize(scraper)
      @scraper = scraper
    end

    def self.sqlite_db_filename
      "data.sqlite"
    end

    def self.sqlite_table_name
      "data"
    end

    def sqlite_db_path
      File.join(data_path, Database.sqlite_db_filename)
    end

    # The actual table names in the current db
    def table_names
      q = sql_query_safe("select name from sqlite_master where type='table'")
      if q
        q = q.map{|h| h["name"]}
        # sqlite_sequence is a special system table (used with autoincrement)
        q.delete("sqlite_sequence")
        q
      else
        []
      end
    end

    # The table that should be listed first because it is the most important
    def first_table_name
      if table_names.include?(Database.sqlite_table_name)
        Database.sqlite_table_name
      else
        table_names.first
      end
    end

    def sql_query(query, readonly = true)
      db = SQLite3::Database.new(sqlite_db_path, results_as_hash: true, type_translation: true, readonly: readonly)
      # If database is busy wait 5s
      db.busy_timeout(5000)
      Database.clean_utf8_query_result(db.execute(query))
    end

    def self.clean_utf8_query_result(array)
      array.map{|row| clean_utf8_query_row(row)}
    end

    def self.clean_utf8_query_row(row)
      result = {}
      row.each {|k,v| result[clean_utf8_string(k)] = clean_utf8_string(v)}
      result
    end

    # Removes bits of strings that are invalid UTF8
    def self.clean_utf8_string(string)
      if string.respond_to?(:encode)
        string.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      else
        string
      end
    end

    def sql_query_safe(query, readonly = true)
      begin
        sql_query(query, readonly)
      rescue SQLite3::CantOpenException, SQLite3::SQLException, SQLite3::NotADatabaseException
        nil
      end
    end

    # Returns 0 if table doesn't exists (or there is some other problem)
    def no_rows(table = table_names.first)
      q = sql_query_safe("select count(*) from #{table}")
      q ? q.first.values.first : 0
    end

    def sqlite_db_size
      if File.exists?(sqlite_db_path)
        File::Stat.new(sqlite_db_path).size
      else
        0
      end
    end

    def clear
      FileUtils.rm sqlite_db_path
    end

    def write_sqlite_database(content)
      FileUtils.mkdir_p data_path
      File.open(sqlite_db_path, 'wb') {|file| file.write(content) }
    end

    def standardise_table_name(table_name)
      sql_query_safe("ALTER TABLE #{table_name} RENAME TO #{Database.sqlite_table_name}", false)
    end

    def select_first_ten(table = table_names.first)
      "select * from #{table} limit 10"
    end

    def select_all(table = table_names.first)
      "select * from #{table}"
    end

    def first_ten_rows(table = table_names.first)
      r = sql_query_safe(select_first_ten(table))
      r ? r : []
    end

    def self.tidy_data_path(data_path)
      # First get all the files in the data directory
      filenames = Dir.entries(data_path)
      filenames.delete(".")
      filenames.delete("..")
      filenames.delete(sqlite_db_filename)
      FileUtils.rm_rf filenames.map{|f| File.join(data_path, f)}
    end

    # Remove any files or directories in the data_path that are not the actual database
    def tidy_data_path
      Database.tidy_data_path(data_path)
    end

    def self.diffstat_table(table, db1, db2)
      # Going to do the dumbest thing first and just count the number of records
      # This is obviously not the way to do this in general
      count1 = db1.execute("SELECT COUNT(*) FROM #{table}").first.values.first
      count2 = db2.execute("SELECT COUNT(*) FROM #{table}").first.values.first
      {added: (count2 - count1), removed: 0, changed: 0}
    end
  end
end
