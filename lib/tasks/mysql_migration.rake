# typed: strict
# frozen_string_literal: true

# Tooling for moving the MySQL 5.7 data to MySQL 8.4 on the new server (#1588). See docs/mysql_migration.md.
# Everything is configured by MYSQL_MIGRATION_* environment variables; nothing here writes to the source.
namespace :mysql_migration do
  steps = -> { Morph::MysqlMigration::Steps.new }
  dry_run = -> { ENV["DRY_RUN"] == "1" }

  desc "Run MySQL Shell's upgrade checker for 8.4 against the source database"
  task check_source: :environment do
    steps.call.check_source
  end

  desc "Dump every table from the source, with log_lines cut to the retained rows (DRY_RUN=1 to validate only)"
  task dump: :environment do
    steps.call.dump(dry_run: dry_run.call)
  end

  desc "Archive log_lines to S3 in resumable id-range slices (DRY_RUN=1 to validate only)"
  task archive_log_lines: :environment do
    steps.call.archive_log_lines(dry_run: dry_run.call)
  end

  desc "Restore the cutover dump into an empty MySQL 8.4 database as utf8mb4_unicode_ci (DRY_RUN=1 to validate only)"
  task restore: :environment do
    steps.call.restore(dry_run: dry_run.call)
  end

  desc "Backfill archived log_lines from S3 into the restored database (DRY_RUN=1 to validate only)"
  task backfill_log_lines: :environment do
    steps.call.backfill_log_lines(dry_run: dry_run.call)
  end

  desc "Scrub emails, tokens and webhook URLs from the restored copy. Refuses unless MORPH_REHEARSAL=true"
  task scrub: :environment do
    steps.call.scrub
  rescue Morph::MysqlMigration::ScrubRefused => e
    abort e.message
  end

  desc "Compare source and target row counts and value hashes and record the elapsed time (VERIFY_SCOPE=full after the backfill)"
  task verify: :environment do
    steps.call.verify(scope: ENV.fetch("VERIFY_SCOPE", "retained"))
    puts "Verification passed: source and target match"
  rescue Morph::MysqlMigration::VerificationFailed => e
    abort [e.message, *e.differences.map { |d| "- #{d}" }].join("\n")
  end

  desc "Record CHECKSUM TABLE for the target; with BASELINE=path/to/report.json list the tables that changed since"
  task checksums: :environment do
    changed = steps.call.checksums(baseline_path: ENV.fetch("BASELINE", nil))
    abort "Changed since baseline: #{changed.join(', ')}" if ENV["BASELINE"] && changed.any?
  end
end
