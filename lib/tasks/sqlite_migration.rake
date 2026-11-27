# typed: strict
# frozen_string_literal: true

# Putting rake tasks inside a class to keep sorbet happy
class SqliteMigrationRake
  extend T::Sig
  extend Rake::DSL

  # Settings come from the environment so nothing sensitive is typed into a
  # command line that lands in shell history or a process list.
  sig { params(mode: Symbol).void }
  def self.sync(mode)
    sync = Morph::SqliteMigration::Sync.new(
      source: ENV.fetch("SQLITE_SOURCE", ""),
      destination: ENV.fetch("SQLITE_DESTINATION", ""),
      mode: mode,
      delete: ENV["DELETE"] == "1",
      max_delete: ENV["MAX_DELETE"]&.to_i,
      bwlimit: ENV["BWLIMIT_KBPS"]&.to_i,
      ssh_command: ENV.fetch("SSH_COMMAND", nil),
      dry_run: ENV["DRY_RUN"] == "1"
    )
    puts "Running: #{sync.display_command}"
    result = sync.run { |line| puts line }
    record(result)
  rescue Morph::SqliteMigration::Sync::Error => e
    abort "#{mode} copy failed: #{e.message}"
  end

  sig { params(result: Morph::SqliteMigration::Sync::Result).void }
  def self.record(result)
    puts
    puts result.summary
    log_file = ENV.fetch("LOG_FILE", nil)
    return unless log_file

    File.open(log_file, "a") { |f| f.puts(JSON.generate(result.to_record)) }
    puts "Recorded in #{log_file}"
  end

  namespace :app do
    namespace :sqlite_migration do
      desc "Bulk copy of the scraper SQLite files and repos with rsync (SQLITE_SOURCE, SQLITE_DESTINATION; " \
           "optional SSH_COMMAND, BWLIMIT_KBPS, DRY_RUN=1, LOG_FILE). Safe to re-run: it resumes."
      task bulk: :environment do
        SqliteMigrationRake.sync(:bulk)
      end

      desc "Final delta copy inside the cutover window, after the freeze. Needs DELETE=1 and MAX_DELETE=N to " \
           "remove scrapers deleted since the bulk copy; otherwise it only adds and updates."
      task delta: :environment do
        SqliteMigrationRake.sync(:delta)
      end

      desc "List every file under DIR (default db/scrapers) as path<TAB>size, to OUTPUT or stdout. Read only."
      task manifest: :environment do
        manifest = Morph::SqliteMigration::Manifest.scan(ENV.fetch("DIR", "db/scrapers"))
        if ENV["OUTPUT"]
          File.write(ENV.fetch("OUTPUT"), manifest.to_s)
          puts "Wrote #{manifest.sizes.size} files to #{ENV.fetch('OUTPUT')}"
        else
          print manifest
        end
      end

      desc "Compare SOURCE_MANIFEST with DESTINATION_MANIFEST (file counts and sizes). Exits 1 on any difference."
      task verify: :environment do
        load = ->(var) { Morph::SqliteMigration::Manifest.parse(File.read(ENV.fetch(var))) }
        comparison = Morph::SqliteMigration::Manifest.compare(load.call("SOURCE_MANIFEST"), load.call("DESTINATION_MANIFEST"))
        print Morph::SqliteMigration::ComparisonReport.new(comparison)
        exit(1) unless comparison.match?
      end
    end
  end
end
