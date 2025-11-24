# typed: strict
# frozen_string_literal: true

require "fileutils"
require_relative "support/db_backup_utils"

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

  desc "Create a full backup of the database"
  task backup: :environment do
    FileUtils.mkdir_p("db/backups")
    backup_file = "db/backups/backup.sql.zst"
    backup_path = Rails.root.join(backup_file)
    tmp_file = "#{backup_path}.tmp"
    FileUtils.rm_f(tmp_file)

    puts "Dumping and compressing database..."
    DbBackupUtils.dump_compressed("", "", tmp_file)

    if File.size?(tmp_file)
      FileUtils.mv(tmp_file, backup_path, force: true)
      DbBackupUtils.puts_help(backup_file)
    else
      abort "Failed to create #{tmp_file}!"
    end
  end

  desc "Create a filtered backup of the database for use in development"
  task filtered_backup: :environment do
    FileUtils.mkdir_p("db/backups")
    backup_file = "db/backups/filtered_backup.sql.zst"
    backup_path = Rails.root.join(backup_file)
    tmp_file = "#{backup_path}.tmp"
    FileUtils.rm_f(tmp_file)

    # Get filtered owner IDs
    owner_ids = Owner.where(
      "email LIKE '%@heggie.biz' OR email like '%@oaf.org.au' or admin = 1 or email like '%@jamezpolley.com' or nickname = 'planningalerts-scrapers'"
    ).pluck(:id)
    owner_ids += Owner.order(created_at: :desc).limit(5).pluck(:id)
    owner_ids.uniq!
    puts "Found #{owner_ids.count} owners to include"

    # Dump filtered owners
    puts "Dumping filtered owners data..."
    DbBackupUtils.dump_with_id_batches("owners", "id", owner_ids, tmp_file, compress: true)

    # Dump owner-dependent tables filtered by owner_id
    %w[organizations_users alerts contributions].each do |table|
      puts "Dumping filtered #{table} data..."
      DbBackupUtils.dump_with_id_batches(table, "user_id", owner_ids, tmp_file,
                                         append: true, compress: true)
    end

    # Get scraper IDs for filtered owners
    scraper_ids = Scraper.where(owner_id: owner_ids).pluck(:id)
    puts "Found #{scraper_ids.count} scrapers to include"

    # Dump filtered scrapers
    puts "Dumping filtered scrapers data..."
    DbBackupUtils.dump_with_id_batches("scrapers", "id", scraper_ids, tmp_file,
                                       append: true, compress: true)

    # Dump runs and api_queries
    puts "Dumping filtered runs..."
    DbBackupUtils.dump_with_id_batches("runs", "scraper_id", scraper_ids, tmp_file,
                                       append: true, compress: true)

    puts "Dumping filtered api queries..."
    DbBackupUtils.dump_with_id_batches("api_queries", "scraper_id", scraper_ids, tmp_file,
                                       append: true, compress: true)

    # Get run IDs for filtered scrapers
    run_ids = Run.where(scraper_id: scraper_ids)
                 .where("created_at > ? OR (MOD(id, 10) = 0 AND created_at > ?) OR MOD(id, 100) = 0",
                        5.days.ago, 50.days.ago)
                 .pluck(:id)
    puts "Found #{run_ids.count} runs to include"

    # Dump tables filtered by run_id
    %w[webhook_deliveries log_lines connection_logs metrics].each do |table|
      puts "Dumping #{table}..."
      DbBackupUtils.dump_with_id_batches(table, "run_id", run_ids, tmp_file,
                                         append: true, compress: true)
    end

    # Get all tables we've already handled
    handled_tables = %w[owners organizations_users alerts contributions scrapers runs api_queries 
                       webhook_deliveries log_lines connection_logs metrics]

    # Dump remaining tables
    remaining_tables = ActiveRecord::Base.connection.tables - handled_tables
    puts "Dumping data from remaining #{remaining_tables.size} tables..."

    remaining_tables.each do |table|
      puts "Dumping #{table} data..."
      DbBackupUtils.dump_compressed("", table, tmp_file, append: true)
    end

    if File.size?(tmp_file)
      FileUtils.mv(tmp_file, backup_path, force: true)
      DbBackupUtils.puts_help(backup_file)
    else
      abort "Failed to create #{tmp_file}!"
    end
  end

  namespace :trim do
    desc "Remove old log lines keeping some for both successful and erroneous runs"
    task log_lines: :environment do
      zero_counts = 0
      total_count = 0
      puts "Trimming log lines older than #{LogLine::DISCARD_AFTER_DAYS} days,"
      puts "Keeping at least #{LogLine::KEEP_AT_LEAST_COUNT_PER_STATUS} log lines for both successful and erroneous runs"
      puts "(progress reported each 100 scrapers, or when log lines are deleted)"
      Scraper.order(:full_name).find_each do |scraper|
        $stdout.flush
        count = scraper.trim_log_lines
        if count.zero?
          zero_counts += 1
          print "."
          next if zero_counts < 100
        end
        zero_counts = 0
        puts "", "Removed #{count} log lines from #{scraper.full_name}"
        total_count += count
      end
      puts "", "Removed #{total_count} log lines from #{Scraper.count} scrapers,"
      puts "leaving #{LogLine.count} log lines remaining"
    end

    desc "Remove connection_logs older than a year"
    task connection_logs: :environment do
      puts "Trimming connection_logs older than #{ConnectionLog::DISCARD_AFTER_MONTHS} months ..."
      before_count = ConnectionLog.count
      delete_before = ConnectionLog::DISCARD_AFTER_MONTHS.months.ago
      loop do
        deleted = ConnectionLog.order(:id).where("created_at < ?", delete_before).limit(200).delete_all
        print "."
        break if deleted.zero?

        sleep(0.05)  # Let DB breathe
      end
      after_count = ConnectionLog.count
      puts "Removed #{before_count - after_count} connection_logs, leaving #{after_count} remaining"
    end

    desc "Remove orphaned domains with no connection logs"
    task domains: :environment do
      orphaned_domain_ids = Domain.left_joins(:connection_logs)
                                  .where(connection_logs: { id: nil })
                                  .pluck(:id)
      count = orphaned_domain_ids.count
      puts "Found #{count} orphaned domains"
      orphaned_domain_ids.each_slice(200) do |batch|
        Domain.where(id: batch).delete_all
        print "."
        sleep(0.05)  # Let DB breathe
      end
      puts "\nDeleted #{count} orphaned domains"
    end
  end
end
