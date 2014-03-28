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

    # Page is the maximum number of records that are read into memory at once
    def self.diffstat_table(table, db1, db2, page = 1000)
      # Find the ROWID range that covers both databases
      v1 = db1.execute("SELECT MIN(ROWID), MAX(ROWID) from #{table}")
      v2 = db2.execute("SELECT MIN(ROWID), MAX(ROWID) from #{table}")
      min1, max1 = v1.first
      min2, max2 = v2.first
      if min1.nil? && max1.nil?
        min, max = min2, max2
      elsif min2.nil? && max2.nil?
        min, max = min1, max1
      else
        min = [min1, min2].min
        max = [max1, max2].max
      end
      page_min = min
      page_max = min + page - 1
      added, removed, changed = 0, 0, 0
      while page_min <= max
        result = diffstat_table_rowid_range(table, page_min, page_max, db1, db2)
        added += result[:added]
        removed += result[:removed]
        changed += result[:changed]
        page_min += page
        page_max += page
      end

      {added: added, removed: removed, changed: changed}
    end

    # Needs to be called with a block that given an array of ids
    # returns an array of triplets of the form [id, value1, value2]
    def self.data_changes(ids1, ids2)
      added = ids2 - ids1
      removed = ids1 - ids2
      possibly_changed = ids1 - removed
      unchanged, changed = yield(possibly_changed).partition{|t| t[1] == t[2]}
      unchanged = unchanged.map{|t| t[0]}
      changed = changed.map{|t| t[0]}
      {added: added, removed: removed, changed: changed, unchanged: unchanged}
    end

    def self.changes(db1, db2, ids_query)
      v1, v2 = execute2(db1, db2, ids_query)
      ids1 = v1.map{|r| r.first}
      ids2 = v2.map{|r| r.first}

      data_changes(ids1, ids2) do |possibly_changed|
        values1, values2 = execute2(db1, db2, yield(possibly_changed))
        transformed = []
        values1.each_index do |i|
          t = [values1[i].first, values1[i][1..-1], values2[i][1..-1]]
          transformed << t
        end
        transformed
      end
    end

    def self.table_changes(db1, db2)
      changes(db1, db2, "select name from sqlite_master where type='table'") do |possibly_changed|
        quoted_ids = possibly_changed.map{|n| "'#{n}'"}.join(",")
        "select name,sql from sqlite_master where type='table' AND name IN (#{quoted_ids})"
      end
    end

    def self.diffstat(db1, db2)
      r = table_changes(db1, db2)
      records_added, records_removed, records_changed = 0, 0, 0
      (r[:unchanged] + r[:changed]).each do |table|
        records = diffstat_table(table, db1, db2)
        records_added += records[:added]
        records_removed += records[:removed]
        records_changed += records[:changed]
      end
      r[:added].each do |table|
        records_added += db2.execute("SELECT COUNT(*) FROM #{table}").first.first
      end
      r[:removed].each do |table|
        records_removed += db1.execute("SELECT COUNT(*) FROM #{table}").first.first
      end
      {
        records: {added: records_added, removed: records_removed, changed: records_changed},
        tables:  {added: r[:added].count, removed: r[:removed].count, changed: r[:changed].count}
      }
    end

    private

    def self.execute2(db1, db2, query)
      [db1.execute(query), db2.execute(query)]
    end

    def self.rows_changed_in_range(table, min, max, db1, db2)
      changes(db1, db2, "SELECT ROWID from #{table} WHERE ROWID BETWEEN #{min} AND #{max}") do |possibly_changed|
        quoted_ids = possibly_changed.map{|n| "'#{n}'"}.join(',')
        "SELECT ROWID, * from #{table} WHERE ROWID IN (#{quoted_ids})"
      end
    end

    # Find the difference within a range of rowids
    def self.diffstat_table_rowid_range(table, min, max, db1, db2)
      r = rows_changed_in_range(table, min, max, db1, db2)
      {added: r[:added].count, removed: r[:removed].count, changed: r[:changed].count}
    end
  end
end
