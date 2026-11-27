# typed: strict
# frozen_string_literal: true

# Putting rake tasks inside a class to keep sorbet happy
class SearchMigrationRake
  extend Rake::DSL

  namespace :app do
    namespace :search_migration do
      desc "Rebuild the Elasticsearch indexes from the database and print document counts. Run after the database " \
           "has loaded, with cron and workers stopped. Exits 1 if counts differ. Redis is not carried over."
      task reindex: :environment do
        reindexer = Morph::SearchMigration::Reindexer.new
        counts = reindexer.reindex
        puts
        print Morph::SearchMigration::Reindexer.report(counts)
        exit(1) unless Morph::SearchMigration::Reindexer.ok?(counts)
      end

      desc "Compare Elasticsearch document counts with the database. Optionally SOURCE_COUNTS=Scraper=N,Owner=N " \
           "from the old server for the record. Exits 1 on any difference. Changes nothing."
      task verify: :environment do
        source_counts = Morph::SearchMigration::Reindexer.parse_source_counts(ENV.fetch("SOURCE_COUNTS", ""))
        counts = Morph::SearchMigration::Reindexer.new.counts
        print Morph::SearchMigration::Reindexer.report(counts, source_counts)
        exit(1) unless Morph::SearchMigration::Reindexer.ok?(counts, source_counts)
      end
    end
  end
end
