# typed: strict
# frozen_string_literal: true

namespace :db do
  desc "Database Stats"
  task stats: [:environment] do
    heading_fmt = "%-30s %8s"
    row_fmt = "%-30s %8d"
    puts format(heading_fmt, "Table", "Count")
    puts format(heading_fmt, "-" * 30, "-" * 8)
    db_name = ActiveRecord::Base.connection.current_database
    ActiveRecord::Base.connection.tables.each do |t|
      sql = if ENV["EXACT_COUNT"]
              "select count(*) from #{t}"
            else
              "SELECT TABLE_ROWS FROM information_schema.TABLES WHERE TABLE_SCHEMA = '#{db_name}' AND TABLE_NAME = '#{t}'"
            end
      res = ActiveRecord::Base.connection.exec_query(sql)
      row = res.rows.first
      if row[0] < 100 && ENV["EXACT_COUNT"].nil?
        # fast enough to get an exact count
        sql = "select count(*) from #{t}"
        res = ActiveRecord::Base.connection.exec_query(sql)
        row = res.rows.first
      end
      puts format(row_fmt, t, row[0])
    end
    puts "",
         "Status as of #{Time.new.utc}",
         ENV["EXACT_COUNT"] ? "(exact count)" : "(approximate count - set EXACT_COUNT=1 to get exact)"
  end
end
