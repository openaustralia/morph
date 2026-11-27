# typed: strict
# frozen_string_literal: true

require "fileutils"
require "json"

module Morph
  module MysqlMigration
    # The archive of older log_lines is a set of MySQL Shell dumps, one per range of log_lines ids, each under its
    # own S3 prefix. mysqlsh cannot resume a dump and needs an empty target, so the unit of resumption is the slice:
    # a slice is either complete and listed here, or it is dumped again from scratch.
    #
    # Slices are disjoint and immutable. A later top-up starts after covered_up_to_id, so the manifest only grows.
    # Archiving everything up to the highest id, retained rows included, is deliberate: it overlaps the cutover
    # dump but can never leave a gap, and loadDump replaces duplicate rows by id, which is harmless on immutable rows.
    class ArchiveManifest
      extend T::Sig

      Slice = Struct.new(:name, :from_id, :to_id, :completed_at, keyword_init: true)

      sig { returns(String) }
      attr_reader :path

      sig { params(path: String).void }
      def initialize(path)
        @path = path
        @slices = T.let([], T::Array[Slice])
        load_existing
      end

      sig { returns(T::Array[Slice]) }
      attr_reader :slices

      sig { returns(Integer) }
      def covered_up_to_id
        slices.map(&:to_id).compact.max || 0
      end

      # The first run starts at the lowest id in the table; later runs carry on from where the archive stopped
      sig { params(min_id: Integer, max_id: Integer, slice_rows: Integer).returns(T::Array[Slice]) }
      def pending_slices(min_id:, max_id:, slice_rows:)
        return [] if max_id.zero?

        from = slices.empty? ? min_id : covered_up_to_id + 1
        pending = []
        while from <= max_id
          to = [from + slice_rows - 1, max_id].min
          pending << Slice.new(name: slice_name(from, to), from_id: from, to_id: to)
          from = to + 1
        end
        pending
      end

      sig { params(slice: Slice).void }
      def complete(slice)
        slice.completed_at = Time.now.utc.iso8601
        @slices << slice
        save
      end

      sig { returns(Integer) }
      def total_ids_covered
        slices.sum { |s| s.to_id.to_i - s.from_id.to_i + 1 }
      end

      private

      sig { params(from: Integer, to: Integer).returns(String) }
      def slice_name(from, to)
        format("ids-%<from>012d-%<to>012d", from: from, to: to)
      end

      sig { void }
      def load_existing
        return unless File.exist?(path)

        parsed = JSON.parse(File.read(path))
        @slices = parsed.fetch("slices").map do |s|
          Slice.new(name: s.fetch("name"), from_id: s.fetch("from_id"), to_id: s.fetch("to_id"), completed_at: s["completed_at"])
        end
      end

      sig { void }
      def save
        FileUtils.mkdir_p(File.dirname(path))
        document = { "table" => "log_lines", "slices" => slices.map(&:to_h) }
        File.write("#{path}.tmp", "#{JSON.pretty_generate(document)}\n")
        File.rename("#{path}.tmp", path)
      end
    end
  end
end
