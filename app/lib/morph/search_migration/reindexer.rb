# typed: strict
# frozen_string_literal: true

module Morph
  module SearchMigration
    # Rebuilds the Elasticsearch indexes from the database and reports document
    # counts, for the move to Elasticsearch 8.19 (#1589). Nothing from the old
    # server's index is carried over, so a rebuild on the new server is the
    # whole migration.
    #
    # It uses Searchkick's own Model.reindex, which builds a fresh index, fills
    # it and then swaps the alias, so search keeps working throughout. It only
    # calls the public Searchkick API, so it behaves the same on 7.17 and 8.19.
    # Searching an 8.x server with the 7.17 client also needs the vendor
    # Content-Type override from PR #1613.
    class Reindexer
      extend T::Sig

      class ModelCount < T::Struct
        extend T::Sig

        const :name, String
        const :database_count, Integer
        const :index_count, Integer
        const :seconds, T.nilable(Float)

        sig { returns(T::Boolean) }
        def match?
          database_count == index_count
        end
      end

      # Prints how many documents the new index holds while a reindex runs.
      # Searchkick builds a timestamped index and only swaps the alias at the
      # end, so the newest index behind the alias name is the one being filled.
      class ProgressMonitor
        extend T::Sig

        sig { params(model: T.untyped, expected: Integer, out: T.untyped).void }
        def initialize(model, expected, out)
          @model = model
          @expected = expected
          @out = out
        end

        sig { void }
        def tick
          indexed = newest_index_total
          return if indexed.nil?

          percent = @expected.positive? ? (indexed * 100.0 / @expected).round : 100
          @out.puts("  #{@model.name}: #{indexed} of #{@expected} documents (#{percent}%)")
        end

        private

        sig { returns(T.nilable(Integer)) }
        def newest_index_total
          stats = Searchkick.client.indices.stats(index: "#{@model.search_index.name}_*", metric: "indexing")
          _name, newest = stats.fetch("indices", {}).max_by(&:first)
          newest&.dig("primaries", "indexing", "index_total")
        rescue StandardError
          # Progress is a courtesy. A failed poll must never stop the reindex.
          nil
        end
      end

      sig { params(models: T::Array[T.untyped], out: T.untyped, poll_seconds: Numeric).void }
      def initialize(models: [Scraper, Owner], out: $stdout, poll_seconds: 15)
        @models = models
        @out = out
        @poll_seconds = poll_seconds
      end

      sig { returns(T::Array[ModelCount]) }
      def reindex
        @out.puts("Elasticsearch #{Searchkick.server_version}, Searchkick #{Searchkick::VERSION}")
        @models.map { |model| reindex_model(model) }
      end

      # Counts only. Safe to run at any time and as often as you like.
      sig { returns(T::Array[ModelCount]) }
      def counts
        @models.map { |model| count(model) }
      end

      sig { params(counts: T::Array[ModelCount], source_counts: T::Hash[String, Integer]).returns(String) }
      def self.report(counts, source_counts = {})
        lines = ["Elasticsearch document counts", ""]
        lines << "#{' ' * 10} #{'database'.rjust(12)} #{'index'.rjust(12)} #{'old index'.rjust(12)}"
        counts.each do |c|
          old = source_counts[c.name]
          lines << format("%-10<name>s %12<db>d %12<idx>d %12<old>s %<flag>s",
                          name: c.name, db: c.database_count, idx: c.index_count, old: old || "-",
                          flag: ok?([c], source_counts) ? "" : "differs").rstrip
        end
        lines << ""
        lines << (ok?(counts, source_counts) ? "RESULT: match" : "RESULT: MISMATCH")
        "#{lines.join("\n")}\n"
      end

      # Index matches the database, and the old server's count where one was given
      sig { params(counts: T::Array[ModelCount], source_counts: T::Hash[String, Integer]).returns(T::Boolean) }
      def self.ok?(counts, source_counts = {})
        counts.all? { |c| c.match? && (source_counts[c.name].nil? || source_counts[c.name] == c.index_count) }
      end

      # "Scraper=11127,Owner=5000" as typed from the old server's `_cat/count`
      sig { params(text: String).returns(T::Hash[String, Integer]) }
      def self.parse_source_counts(text)
        text.split(",").to_h do |pair|
          name, number = pair.strip.split("=", 2)
          raise ArgumentError, "expected Name=count, got #{pair.inspect}" unless name && number&.match?(/\A\d+\z/)

          [name, number.to_i]
        end
      end

      private

      sig { params(model: T.untyped).returns(ModelCount) }
      def reindex_model(model)
        expected = model.count
        @out.puts("Reindexing #{model.name} (#{expected} rows)...")
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC).to_f
        with_progress(model, expected) { model.reindex }
        seconds = Process.clock_gettime(Process::CLOCK_MONOTONIC).to_f - started
        result = count(model, seconds)
        @out.puts("Finished #{model.name}: #{result.index_count} documents in #{seconds.round(1)}s")
        result
      end

      sig { params(model: T.untyped, seconds: T.nilable(Float)).returns(ModelCount) }
      def count(model, seconds = nil)
        ModelCount.new(name: model.name, database_count: model.count, index_count: index_count(model), seconds: seconds)
      end

      # The count API is exact. Index#total_docs uses a search, which stops
      # counting at 10,000 and production has more than that many scrapers.
      # Before the first reindex there is no index at all, which is 0 documents.
      sig { params(model: T.untyped).returns(Integer) }
      def index_count(model)
        index = model.search_index
        return 0 unless index.exists?

        Searchkick.client.count(index: index.name)["count"]
      end

      sig { params(model: T.untyped, expected: Integer, block: T.proc.void).void }
      def with_progress(model, expected, &block)
        monitor = ProgressMonitor.new(model, expected, @out)
        thread = Thread.new do
          loop do
            sleep(@poll_seconds)
            monitor.tick
          end
        end
        block.call
      ensure
        thread&.kill
        thread&.join
      end
    end
  end
end
