module Morph
  class SqliteDiff
    def self.diffstat_safe(file1, file2)
      diffstat(file1, file2)
    rescue SQLite3::NotADatabaseException, SQLite3::SQLException
      nil
    end

    def self.diffstat_tables(tables, db1, db2)
      tables.map do |table|
        {
          name: table,
          records: { counts: diffstat_table(table, db1, db2) }
        }
      end
    end

    def self.tables_added(tables, db1, db2)
      tables.map do |table|
        added = db2.execute("SELECT COUNT(*) FROM '#{table}'").first.first
        {
          name: table,
          records: {
            counts: { added: added, removed: 0, changed: 0, unchanged: 0 }
          }
        }
      end
    end

    def self.tables_removed(tables, db1, db2)
      tables.map do |table|
        removed = db1.execute("SELECT COUNT(*) FROM '#{table}'").first.first
        {
          name: table,
          records: {
            counts: { added: 0, removed: removed, changed: 0, unchanged: 0 }
          }
        }
      end
    end

    def self.diffstat_db(db1, db2)
      r = table_changes(db1, db2)

      result = {tables: {counts: {}}, records: {counts: {}}}

      result[:tables][:unchanged] = diffstat_tables(r[:unchanged], db1, db2)
      result[:tables][:changed] = diffstat_tables(r[:changed], db1, db2)
      result[:tables][:added] = tables_added(r[:added], db1, db2)
      result[:tables][:removed] = tables_removed(r[:removed], db1, db2)
      result[:tables][:counts][:added] =
        result[:tables][:added].count
      result[:tables][:counts][:removed] =
        result[:tables][:removed].count
      result[:tables][:counts][:changed] =
        result[:tables][:changed].count
      result[:tables][:counts][:unchanged] =
        result[:tables][:unchanged].count

      # Now let's work out the totals
      result[:records][:counts][:added] =
        (result[:tables][:unchanged] +
        result[:tables][:changed] +
        result[:tables][:added]).sum {|t| t[:records][:counts][:added]}
      result[:records][:counts][:removed] =
        (result[:tables][:unchanged] +
        result[:tables][:changed] +
        result[:tables][:removed]).sum {|t| t[:records][:counts][:removed]}
      result[:records][:counts][:changed] =
        (result[:tables][:unchanged] +
        result[:tables][:changed]).sum {|t| t[:records][:counts][:changed]}
      result[:records][:counts][:unchanged] =
        (result[:tables][:unchanged] +
        result[:tables][:changed]).sum {|t| t[:records][:counts][:unchanged]}


      result
    end

    def self.diffstat(file1, file2)
      SQLite3::Database.new(file1) do |db1|
        SQLite3::Database.new(file2) do |db2|
          return diffstat_db(db1, db2)
        end
      end
    end

    def self.table_changes(db1, db2)
      changes(db1, db2, "select name from sqlite_master where type='table'") do |possibly_changed|
        quoted_ids = possibly_changed.map{|n| "'#{n}'"}.join(",")
        "select name,sql from sqlite_master where type='table' AND name IN (#{quoted_ids})"
      end
    end

    # Page is the maximum number of records that are read into memory at once
    def self.diffstat_table(table, db1, db2, page = 1000)
      # Find the ROWID range that covers both databases
      v1 = db1.execute("SELECT MIN(ROWID), MAX(ROWID) from '#{table}'")
      v2 = db2.execute("SELECT MIN(ROWID), MAX(ROWID) from '#{table}'")
      min1, max1 = v1.first
      min2, max2 = v2.first
      if min1.nil? && max1.nil? && min2.nil? && max2.nil?
        min = 1
        max = 1
      elsif min1.nil? && max1.nil?
        min = min2
        max = max2
      elsif min2.nil? && max2.nil?
        min = min1
        max = max1
      else
        min = [min1, min2].min
        max = [max1, max2].max
      end
      page_min = min
      page_max = min + page - 1
      added = 0
      removed = 0
      changed = 0
      unchanged = 0
      while page_min <= max
        result = diffstat_table_rowid_range(table, page_min, page_max, db1, db2)
        added += result[:added]
        removed += result[:removed]
        changed += result[:changed]
        unchanged += result[:unchanged]
        page_min += page
        page_max += page
      end

      { added: added, removed: removed, changed: changed, unchanged: unchanged }
    end

    def self.changes(db1, db2, ids_query)
      v1, v2 = execute2(db1, db2, ids_query)
      ids1 = v1.map(&:first)
      ids2 = v2.map(&:first)

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

    # Find the difference within a range of rowids
    def self.diffstat_table_rowid_range(table, min, max, db1, db2)
      r = rows_changed_in_range(table, min, max, db1, db2)
      {
        added: r[:added].count,
        removed: r[:removed].count,
        changed: r[:changed].count,
        unchanged: r[:unchanged].count
      }
    end

    def self.rows_changed_in_range(table, min, max, db1, db2)
      changes(db1, db2, "SELECT ROWID from '#{table}' WHERE ROWID BETWEEN #{min} AND #{max}") do |possibly_changed|
        quoted_ids = possibly_changed.map{|n| "'#{n}'"}.join(',')
        "SELECT ROWID, * from '#{table}' WHERE ROWID IN (#{quoted_ids})"
      end
    end

    # Needs to be called with a block that given an array of ids
    # returns an array of triplets of the form [id, value1, value2]
    def self.data_changes(ids1, ids2)
      added = ids2 - ids1
      removed = ids1 - ids2
      possibly_changed = ids1 - removed
      unchanged, changed = yield(possibly_changed).partition do |t|
        t[1] == t[2]
      end
      unchanged = unchanged.map { |t| t[0] }
      changed = changed.map { |t| t[0] }
      { added: added, removed: removed, changed: changed, unchanged: unchanged }
    end

    def self.execute2(db1, db2, query)
      [db1.execute(query), db2.execute(query)]
    end
  end
end