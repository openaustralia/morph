# typed: strict
# frozen_string_literal: true

require "active_support/core_ext/numeric/bytes"

module DbBackupUtils
  # Returns a string containing the mysqldump command to run
  # with password in ENV if a block is given, otherwise in the string
  def self.mysqldump_cmd(options = "")
    config = ActiveRecord::Base.connection_config
    cmd = "mysqldump --no-tablespaces --single-transaction"
    cmd += " -u#{config[:username]}" if config[:username]
    cmd += " -p#{config[:password]}" if config[:password] && !block_given?
    cmd += " -h#{config[:host]}" if config[:host]
    cmd += " -P#{config[:port]}" if config[:port]
    cmd += " #{options} #{config[:database]}"
    if block_given?
      begin
        prev = ENV.fetch("MYSQL_PWD", nil)
        ENV["MYSQL_PWD"] = config[:password]
        yield cmd
      ensure
        ENV["MYSQL_PWD"] = prev
      end
    end
    cmd
  end

  # Run mysqldump with compression via pipe
  def self.dump_compressed(options, tables, output_file, append: false)
    redirect = append ? ">>" : ">"
    table_list = tables.is_a?(Array) ? tables.join(" ") : tables
    mysqldump_cmd(options) do |cmd|
      # Use bash -c with proper escaping
      full_cmd = "set -o pipefail; #{cmd} #{table_list} | zstd -T0 -6 #{redirect} #{output_file}"
      system("bash", "-c", full_cmd) || abort("Failed to dump/compress #{table_list}!")
    end
  end

  # Dump table with ID batches to handle large WHERE IN clauses
  def self.dump_with_id_batches(table, column, ids, output_file, append: false, compress: false)
    return File.write(output_file, "") if ids.empty? && !append

    first_batch = !append
    current_batch = []

    ids.each do |id|
      test_batch = current_batch + [id]
      test_clause = "#{column} in (#{test_batch.join(',')})"

      # Check if adding this ID would exceed 800 chars
      if test_clause.length > 800
        # Dump the current batch
        dump_batch(table, column, current_batch, output_file, first_batch, compress)
        first_batch = false
        current_batch = [id]
      else
        current_batch << id
      end
    end

    # Dump remaining IDs
    dump_batch(table, column, current_batch, output_file, first_batch, compress) if current_batch.any?
  end

  def self.puts_help(backup_file)
    size_bytes = File.size(backup_file)
    human_size = begin
      size_bytes.to_s(:human_size)
    rescue StandardError => e
      Rails.logger.error("Failed to convert #{size_bytes} to human size: #{e}")
      "#{size_bytes} bytes"
    end
    $stdout.puts "Created #{backup_file} backup #{human_size}"
    $stdout.puts ""
    $stdout.puts "To restore this backup:"
    $stdout.puts "  bundle exec rake db:drop db:create  # Create empty database"
    $stdout.puts "  zstd -dc #{backup_file} | bundle exec rails db -p"
  end

  def self.dump_batch(table, column, ids, output_file, first_batch, compress)
    return if ids.empty?

    ids_list = ids.join(",")
    create_info = first_batch ? "" : "--no-create-info"
    # Use double quotes for the where clause to avoid shell interpretation issues
    options = %(#{create_info} --where="#{column} in (#{ids_list})")

    if compress
      dump_compressed(options, table, output_file, append: !first_batch)
    else
      redirect = first_batch ? ">" : ">>"
      mysqldump_cmd(options) do |cmd|
        system("#{cmd} #{table} #{redirect} #{output_file}") || abort("Failed to dump #{table}!")
      end
    end
  end
end
