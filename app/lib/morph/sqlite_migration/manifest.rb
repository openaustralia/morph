# typed: strict
# frozen_string_literal: true

require "find"

module Morph
  module SqliteMigration
    # A listing of every regular file under a directory, with its size in bytes.
    #
    # The text form is one `relative/path<TAB>size` line per file, sorted. The
    # old server runs main on Ruby 3.0.7 and cannot run this class, so it makes
    # the same listing with plain shell:
    #
    #   find db/scrapers -type f -printf '%P\t%s\n' | sort > manifest.tsv
    #
    # This class only reads. It never writes to the directory it scans.
    class Manifest
      extend T::Sig

      class Comparison < T::Struct
        extend T::Sig

        const :source_summary, T::Hash[Symbol, Integer]
        const :destination_summary, T::Hash[Symbol, Integer]
        const :missing_from_destination, T::Array[String]
        const :extra_in_destination, T::Array[String]
        const :size_mismatches, T::Array[[String, Integer, Integer]]

        sig { returns(T::Boolean) }
        def match?
          missing_from_destination.empty? && extra_in_destination.empty? && size_mismatches.empty?
        end
      end

      sig { returns(T::Hash[String, Integer]) }
      attr_reader :sizes

      sig { params(sizes: T::Hash[String, Integer]).void }
      def initialize(sizes)
        @sizes = sizes
      end

      # Symlinks are skipped (File.file? follows them, so check lstat), because
      # rsync -a copies them as links and they have no size worth comparing.
      sig { params(root: String).returns(Manifest) }
      def self.scan(root)
        raise ArgumentError, "#{root} is not a directory" unless File.directory?(root)

        # db/scrapers is a Capistrano linked_dir, so the root is usually a
        # symlink, and Find does not enter a symlink.
        real_root = File.realpath(root)
        prefix = File.join(real_root, "")
        sizes = T.let({}, T::Hash[String, Integer])
        Find.find(real_root) do |path|
          # Scrapers are running, so a file can vanish between listing and stat
          stat = begin
            File.lstat(path)
          rescue Errno::ENOENT, Errno::ENOTDIR
            next
          end
          next unless stat.file?

          sizes[path.delete_prefix(prefix)] = stat.size
        end
        new(sizes)
      end

      sig { params(text: String).returns(Manifest) }
      def self.parse(text)
        sizes = T.let({}, T::Hash[String, Integer])
        text.each_line.with_index(1) do |line, number|
          line = line.chomp
          next if line.empty?

          # Split on the last tab, because a file name can contain tabs
          path, _tab, size = line.rpartition("\t")
          raise ArgumentError, "line #{number} is not path<TAB>size" if path.empty? || !size.match?(/\A\d+\z/)

          sizes[path] = size.to_i
        end
        new(sizes)
      end

      sig { returns(String) }
      def to_s
        sizes.sort.map { |path, size| "#{path}\t#{size}\n" }.join
      end

      # File and byte counts overall, for *.sqlite files, and for each top level
      # directory (db/scrapers has data/ and repos/), so the figures line up
      # with the 123 GB measured in #1558.
      sig { returns(T::Hash[Symbol, Integer]) }
      def summary
        result = Hash.new(0)
        sizes.each do |path, size|
          result[:files] += 1
          result[:bytes] += size
          if path.end_with?(".sqlite")
            result[:sqlite_files] += 1
            result[:sqlite_bytes] += size
          end
          top = path.include?("/") ? path.split("/", 2).first : "(top level)"
          result[:"#{top}_files"] += 1
          result[:"#{top}_bytes"] += size
        end
        result.to_h
      end

      sig { params(source: Manifest, destination: Manifest).returns(Comparison) }
      def self.compare(source, destination)
        missing = source.sizes.keys - destination.sizes.keys
        extra = destination.sizes.keys - source.sizes.keys
        mismatches = (source.sizes.keys & destination.sizes.keys).filter_map do |path|
          a = T.must(source.sizes[path])
          b = T.must(destination.sizes[path])
          [path, a, b] if a != b
        end
        Comparison.new(
          source_summary: source.summary,
          destination_summary: destination.summary,
          missing_from_destination: missing.sort,
          extra_in_destination: extra.sort,
          size_mismatches: mismatches.sort_by(&:first)
        )
      end
    end
  end
end
