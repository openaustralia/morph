# typed: strict
# frozen_string_literal: true

module Morph
  module MysqlMigration
    # Which log_lines the cutover dump carries, by the same rule as Scraper#trim_log_lines:
    # lines of runs created in the last LogLine::DISCARD_AFTER_DAYS days, plus the lines of each scraper's
    # most recent LogLine::KEEP_AT_LEAST_COUNT_PER_STATUS successful and unsuccessful runs.
    #
    # It reads the source server through a plain client, because the source is not the app's own database.
    # MySQL 5.7 has no window functions, so the per-scraper rule is applied in Ruby over a streamed list of runs.
    # The ids are written into the filter as literals: a subquery in a mysqlsh `where` is untested (#1569).
    # Lines with a NULL run_id are kept, because trim_log_lines never deletes them.
    class RetainedLogLines
      extend T::Sig

      sig { params(client: T.untyped, now: Time).void }
      def initialize(client, now: Time.now.utc)
        @client = client
        @now = now
      end

      sig { returns(Time) }
      def cutoff
        @now - (LogLine::DISCARD_AFTER_DAYS * 24 * 60 * 60)
      end

      # Every run created after the cutoff has an id at or above this one, so the recent part of the filter is a
      # primary key range and the dump does not have to scan the whole table. Ids rise with created_at, so the range
      # holds nothing older than the cutoff in practice, and a run that was it would only be kept, never lost.
      sig { returns(T.nilable(Integer)) }
      def recent_boundary_run_id
        @recent_boundary_run_id ||= T.let(
          @client.query("SELECT MIN(id) FROM runs WHERE created_at > '#{cutoff.utc.strftime('%Y-%m-%d %H:%M:%S')}'",
                        as: :array).first&.first&.to_i,
          T.nilable(Integer)
        )
      end

      # Run ids below the recent boundary that are kept only because they are among a scraper's latest runs
      sig { returns(T::Array[Integer]) }
      def kept_older_run_ids
        @kept_older_run_ids ||= T.let(compute_kept_older_run_ids, T.nilable(T::Array[Integer]))
      end

      sig { returns(String) }
      def where_clause
        parts = ["run_id IS NULL"]
        boundary = recent_boundary_run_id
        parts << "run_id >= #{boundary}" if boundary
        parts << "run_id IN (#{kept_older_run_ids.join(',')})" if kept_older_run_ids.any?
        parts.join(" OR ")
      end

      sig { returns(Integer) }
      def expected_row_count
        @client.query("SELECT COUNT(*) FROM log_lines WHERE #{where_clause}", as: :array).first.first.to_i
      end

      sig { returns(T::Hash[String, T.untyped]) }
      def summary
        {
          "cutoff" => cutoff.utc.iso8601,
          "recent_boundary_run_id" => recent_boundary_run_id,
          "kept_older_run_count" => kept_older_run_ids.size,
          "where_clause_bytes" => where_clause.bytesize,
          "expected_row_count" => expected_row_count
        }
      end

      private

      sig { returns(T::Array[Integer]) }
      def compute_kept_older_run_ids
        boundary = recent_boundary_run_id
        kept = T.let([], T::Array[Integer])
        current_scraper = T.let(nil, T.nilable(Integer))
        successes = 0
        failures = 0

        rows = @client.query("SELECT id, scraper_id, status_code FROM runs WHERE scraper_id IS NOT NULL ORDER BY scraper_id, id DESC",
                             as: :array, stream: true, cache_rows: false)
        rows.each do |id, scraper_id, status_code|
          if scraper_id != current_scraper
            current_scraper = scraper_id
            successes = 0
            failures = 0
          end
          # A NULL status_code is neither successful nor unsuccessful, as in trim_log_lines
          if status_code.nil?
            next
          elsif status_code.zero?
            successes += 1
            keep = successes <= LogLine::KEEP_AT_LEAST_COUNT_PER_STATUS
          else
            failures += 1
            keep = failures <= LogLine::KEEP_AT_LEAST_COUNT_PER_STATUS
          end

          kept << id if keep && (boundary.nil? || id < boundary)
        end
        # trim_log_lines works scraper by scraper, so it never deletes lines of runs that have no scraper
        rows = @client.query("SELECT id FROM runs WHERE scraper_id IS NULL", as: :array)
        rows.each { |(id)| kept << id if boundary.nil? || id < boundary }
        kept.sort
      end
    end
  end
end
