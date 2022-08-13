# typed: true
# frozen_string_literal: true

module Morph
  class SqliteDiff
    extend T::Sig

    sig { params(file1: String, file2: String).returns(DiffStruct) }
    def self.diffstat_safe(file1, file2)
      diffstat(file1, file2)
    rescue *Database::CORRUPT_DATABASE_EXCEPTIONS, SQLite3::SQLException
      nil
    end

    class CountsStruct < T::Struct
      const :added, Integer
      const :removed, Integer
      const :changed, Integer
      const :unchanged, Integer
    end

    class TableDiffStruct < T::Struct
      const :name, String
      const :records, CountsStruct
    end

    class TablesDiffStruct < T::Struct
      const :unchanged, T::Array[TableDiffStruct]
      const :changed, T::Array[TableDiffStruct]
      const :added, T::Array[TableDiffStruct]
      const :removed, T::Array[TableDiffStruct]
      const :counts, CountsStruct
    end

    class DiffStruct < T::Struct
      const :tables, TablesDiffStruct
      const :records, CountsStruct
    end

    sig { params(tables: T::Array[String], db1: SQLite3::Database, db2: SQLite3::Database).returns(T::Array[TableDiffStruct]) }
    def self.diffstat_tables(tables, db1, db2)
      tables.map do |table|
        TableDiffStruct.new(
          name: table,
          records: diffstat_table(table, db1, db2)
        )
      end
    end

    sig { params(tables: T::Array[String], _db1: SQLite3::Database, db2: SQLite3::Database).returns(T::Array[TableDiffStruct]) }
    def self.tables_added(tables, _db1, db2)
      tables.map do |table|
        added = db2.execute("SELECT COUNT(*) FROM '#{table}'").first.first
        TableDiffStruct.new(
          name: table,
          records: CountsStruct.new(added: added, removed: 0, changed: 0, unchanged: 0)
        )
      end
    end

    sig { params(tables: T::Array[String], db1: SQLite3::Database, _db2: SQLite3::Database).returns(T::Array[TableDiffStruct]) }
    def self.tables_removed(tables, db1, _db2)
      tables.map do |table|
        removed = db1.execute("SELECT COUNT(*) FROM '#{table}'").first.first
        TableDiffStruct.new(
          name: table,
          records: CountsStruct.new(added: 0, removed: removed, changed: 0, unchanged: 0)
        )
      end
    end

    sig { params(db1: SQLite3::Database, db2: SQLite3::Database).returns(DiffStruct) }
    def self.diffstat_db(db1, db2)
      r = table_changes(db1, db2)

      unchanged = diffstat_tables(r[:unchanged], db1, db2)
      changed = diffstat_tables(r[:changed], db1, db2)
      added = tables_added(r[:added], db1, db2)
      removed = tables_removed(r[:removed], db1, db2)

      DiffStruct.new(
        tables: TablesDiffStruct.new(
          unchanged: unchanged,
          changed: changed,
          added: added,
          removed: removed,
          counts: CountsStruct.new(
            unchanged: unchanged.count,
            changed: changed.count,
            added: added.count,
            removed: removed.count
          )
        ),
        records: CountsStruct.new(
          added: (unchanged + changed + added).sum { |t| t.records.added },
          removed: (unchanged + changed + removed).sum { |t| t.records.removed },
          changed: (unchanged + changed).sum { |t| t.records.changed },
          unchanged: (unchanged + changed).sum { |t| t.records.unchanged }
        )
      )
    end

    # sig { params(file1: String, file2: String).returns(DiffStruct) }
    def self.diffstat(file1, file2)
      SQLite3::Database.new(file1) do |db1|
        SQLite3::Database.new(file2) do |db2|
          return diffstat_db(db1, db2)
        end
      end
    end

    def self.table_changes(db1, db2)
      changes(db1, db2, "select name from sqlite_master where type='table'") do |possibly_changed|
        quoted_ids = possibly_changed.map { |n| "'#{n}'" }.join(",")
        "select name,sql from sqlite_master where type='table' AND name IN (#{quoted_ids})"
      end
    end

    # Returns [min, max]
    def self.min_and_max_rowid(table, db)
      v = db.execute("SELECT MIN(ROWID), MAX(ROWID) from '#{table}'")
      v.first
    end

    # Find the ROWID range that covers both databases and return as
    # [min, max]
    def self.spanning_rowid_table(table, db1, db2)
      min1, max1 = min_and_max_rowid(table, db1)
      min2, max2 = min_and_max_rowid(table, db2)
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
      [min, max]
    end

    # Page is the maximum number of records that are read into memory at once
    sig { params(table: String, db1: SQLite3::Database, db2: SQLite3::Database, page: Integer).returns(CountsStruct) }
    def self.diffstat_table(table, db1, db2, page = 1000)
      min, max = spanning_rowid_table(table, db1, db2)
      added = 0
      removed = 0
      changed = 0
      unchanged = 0
      (min..max).each_slice(page) do |p|
        result = diffstat_table_rowid_range(table, p[0], p[-1], db1, db2)
        added += result[:added]
        removed += result[:removed]
        changed += result[:changed]
        unchanged += result[:unchanged]
      end
      CountsStruct.new(added: added, removed: removed, changed: changed, unchanged: unchanged)
    end

    def self.changes(db1, db2, ids_query)
      v1, v2 = execute2(db1, db2, ids_query)
      ids1 = v1.map(&:first)
      ids2 = v2.map(&:first)

      data_changes(ids1, ids2) do |possibly_changed|
        values1, values2 = execute2(db1, db2, yield(possibly_changed))
        values1.zip(values2).map do |value1, value2|
          [value1.first, value1[1..-1], value2[1..-1]]
        end
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
        quoted_ids = possibly_changed.map { |n| "'#{n}'" }.join(",")
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
