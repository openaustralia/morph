# typed: strict
# frozen_string_literal: true

module Morph
  module SqliteMigration
    # Turns a Manifest::Comparison into plain text that can be pasted into the
    # dry run record on the rehearsal ticket.
    class ComparisonReport
      extend T::Sig

      LISTED = 20

      sig { params(comparison: Manifest::Comparison).void }
      def initialize(comparison)
        @comparison = comparison
      end

      sig { returns(String) }
      def to_s
        lines = ["SQLite copy verification", ""]
        lines.concat(summary_table)
        lines << ""
        lines.concat(problems)
        lines << (@comparison.match? ? "RESULT: match" : "RESULT: MISMATCH")
        "#{lines.join("\n")}\n"
      end

      private

      sig { returns(T::Array[String]) }
      def summary_table
        source = @comparison.source_summary
        destination = @comparison.destination_summary
        keys = (source.keys | destination.keys).sort
        rows = keys.map do |key|
          s = source.fetch(key, 0)
          d = destination.fetch(key, 0)
          format("%-22<key>s %16<src>s %16<dst>s %<flag>s", key: key, src: s, dst: d, flag: s == d ? "" : "differs").rstrip
        end
        ["#{' ' * 22} #{'source'.rjust(16)} #{'destination'.rjust(16)}"] + rows
      end

      sig { returns(T::Array[String]) }
      def problems
        lines = []
        lines.concat(listing("Missing from destination", @comparison.missing_from_destination))
        lines.concat(listing("Extra in destination", @comparison.extra_in_destination))
        lines.concat(listing("Size differs (path, source, destination)",
                             @comparison.size_mismatches.map { |p, a, b| "#{p}\t#{a}\t#{b}" }))
        lines
      end

      sig { params(title: String, items: T::Array[String]).returns(T::Array[String]) }
      def listing(title, items)
        return [] if items.empty?

        shown = items.first(LISTED)
        more = items.size - shown.size
        [
          "#{title}: #{items.size}",
          *shown.map { |item| "  #{item}" },
          *(more.positive? ? ["  ... and #{more} more"] : []),
          ""
        ]
      end
    end
  end
end
