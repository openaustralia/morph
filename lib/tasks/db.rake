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


  desc "Create a filtered backup of the database"
  task filtered_backup: :environment do
    # Setup paths
    FileUtils.mkdir_p("db/backups")
    backup_file = Rails.root.join("db/backups/filtered_backup.sql")
    temp_dir = Rails.root.join("tmp")
    temp_files = []
    
    begin
      # Dump complete database structure (no data)
      puts "Dumping complete database structure..."
      structure_file = temp_dir.join("structure.sql")
      temp_files << structure_file
      system_with_time("mysqldump --no-data morph > #{structure_file}")
      abort "Failed to create #{structure_file}!" unless File.size!(structure_file)
      
      # Get filtered owner IDs
      owner_ids = Owner.where(
        "name LIKE 'ian%' OR name LIKE 'planning%' OR name LIKE 'mlander%' OR name LIKE 'openaust%' OR name LIKE 'jame%'"
      ).pluck(:id)
      # Add last 20 created owners
      owner_ids += Owner.order(created_at: :desc).limit(20).pluck(:id)
      owner_ids.uniq!
      puts "Found #{owner_ids.count} owners to include"
      
      # Dump data for lookup tables (excluding owner-dependent tables - we'll filter those)
      puts "Dumping lookup tables data..."
      lookup_file = temp_dir.join("lookup_data.sql")
      temp_files << lookup_file
      lookup_tables = %w[
        active_admin_comments collaborations
        create_scraper_progresses domains 
        site_settings variables webhooks
      ]
      system_with_time("mysqldump --no-create-info morph #{lookup_tables.join(' ')} > #{lookup_file}")
      abort "Failed to create #{lookup_file}!" unless File.size!(lookup_file)
      
      # Dump filtered owners
      puts "Dumping filtered owners data..."
      owners_file = temp_dir.join("owners_data.sql")
      temp_files << owners_file
      dump_with_id_batches("owners", "id", owner_ids, owners_file)
      
      # Dump owner-dependent tables filtered by owner_id
      owner_dependent_tables = %w[organizations_users alerts contributions]
      owner_dependent_tables.each do |table|
        puts "Dumping filtered #{table} data..."
        file = temp_dir.join("#{table}_data.sql")
        temp_files << file
        dump_with_id_batches(table, "owner_id", owner_ids, file)
        abort "Failed to create #{file}!" unless File.size!(file)
      end
      
      # Get scraper IDs for filtered owners
      scraper_ids = Scraper.where(owner_id: owner_ids).pluck(:id)
      puts "Found #{scraper_ids.count} scrapers to include"
      
      # Dump filtered scrapers
      puts "Dumping filtered scrapers data..."
      scrapers_file = temp_dir.join("scrapers_data.sql")
      temp_files << scrapers_file
      dump_with_id_batches("scrapers", "id", scraper_ids, scrapers_file)
      abort "Failed to create #{scrapers_file}!" unless File.size!(scrapers_file)
      
      # Dump filtered runs and api_queries
      puts "Dumping filtered runs and api_queries data..."
      runs_file = temp_dir.join("runs_data.sql")
      temp_files << runs_file
      dump_with_id_batches("runs", "scraper_id", scraper_ids, runs_file)
      abort "Failed to create #{runs_file}!" unless File.size!(runs_file)
      
      api_queries_file = temp_dir.join("api_queries_data.sql")
      temp_files << api_queries_file
      dump_with_id_batches("api_queries", "scraper_id", scraper_ids, api_queries_file)
      abort "Failed to create #{api_queries_file}!" unless File.size!(api_queries_file)
      
      # Get run IDs for filtered scrapers
      run_ids = Run.where(scraper_id: scraper_ids).pluck(:id)
      puts "Found #{run_ids.count} runs to process for related tables"
      
      # Dump tables filtered by run_id
      filtered_runs_file = temp_dir.join("filtered_by_runs.sql")
      temp_files << filtered_runs_file
      File.write(filtered_runs_file, "")
      
      %w[webhook_deliveries log_lines connection_logs metrics].each do |table|
        puts "Dumping #{table}..."
        dump_with_id_batches(table, "run_id", run_ids, filtered_runs_file, append: true)
      end
      abort "Failed to create #{filtered_runs_file}!" unless File.size!(filtered_runs_file)
      
      # Combine all files
      puts "Creating final backup..."
      system("cat #{temp_files.join(' ')} > #{backup_file}")
      
      puts "Done! Output in #{backup_file}"
    ensure
      # Clean up temp files
      temp_files.each { |f| File.delete(f) if File.exist?(f) }
    end
  end

  namespace :trim do
    desc "Trim old log lines keeping some for both successful and erroneous runs"
    task log_lines: :environment do
      zero_counts = 0
      total_count = 0
      puts "Trimming log lines older than #{LogLine::DISCARD_AFTER_DAYS} days,"
      puts "Keeping at least #{LogLine::KEEP_AT_LEAST_COUNT_PER_STATUS} log lines for both successful and erroneous runs"
      puts "(progress reported each 50 scrapers, or when log lines are deleted)"
      Scraper.order(:full_name).each do |scraper|
        count = scraper.trim_log_lines
        if count.zero?
          zero_counts += 1
          print "."
          next if zero_counts < 100
        end
        zero_counts = 0
        puts "", "Removed #{count} log lines from #{scraper.full_name}"
      end
      puts "", "Removed #{total_count} log lines from #{Scraper.count} scrapers, leaving #{LogLine.count} log lines remaining"
    end
  end
  
  private
  
  def system_with_time(command)
    start = Time.now
    result = system(command)
    puts "  Time: #{(Time.now - start).round(2)}s"
    result
  end
  
  def dump_with_id_batches(table, column, ids, output_file, append: false)
    return File.write(output_file, "") if ids.empty? && !append
    
    first_batch = !append
    current_batch = []
    
    ids.each do |id|
      test_batch = current_batch + [id]
      test_clause = "#{column} in (#{test_batch.join(',')})"
      
      # Check if adding this ID would exceed 800 chars
      if test_clause.length > 800
        # Dump current batch
        dump_batch(table, column, current_batch, output_file, first_batch)
        first_batch = false
        current_batch = [id]
      else
        current_batch << id
      end
    end
    
    # Dump remaining IDs
    dump_batch(table, column, current_batch, output_file, first_batch) if current_batch.any?
  end
  
  def dump_batch(table, column, ids, output_file, first_batch)
    return if ids.empty?
    
    ids_list = ids.join(',')
    redirect = first_batch ? ">" : ">>"
    system("mysqldump --no-create-info --where=\"#{column} in (#{ids_list})\" morph #{table} #{redirect} #{output_file}")
  end
end
