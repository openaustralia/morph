# typed: strict
# frozen_string_literal: true

require "fileutils"
require "json"

module Morph
  module MysqlMigration
    # Records what a migration step did and how long it took, as JSON on disk and a line on stdout,
    # so a dry run's timings can be set against the 4-hour bar.
    class Report
      extend T::Sig

      sig { returns(String) }
      attr_reader :name

      sig { returns(T::Hash[String, T.untyped]) }
      attr_reader :data

      sig { params(name: String, dir: String).void }
      def initialize(name, dir:)
        @name = name
        @dir = dir
        @data = T.let({ "step" => name }, T::Hash[String, T.untyped])
      end

      sig { params(key: String, value: T.untyped).void }
      def []=(key, value) # rubocop:disable Rails/Delegate
        @data[key] = value
      end

      # Runs the block, records start, finish and elapsed time (monotonic clock), and writes the file
      # even when the block raises, so a failed step still leaves its timing behind.
      sig { type_parameters(:U).params(block: T.proc.returns(T.type_parameter(:U))).returns(T.type_parameter(:U)) }
      def measure(&block)
        @data["started_at"] = Time.now.utc.iso8601
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        begin
          result = yield
          @data["outcome"] = "succeeded"
          result
        rescue StandardError => e
          @data["outcome"] = "failed"
          @data["error"] = e.message
          raise
        ensure
          @data["finished_at"] = Time.now.utc.iso8601
          @data["elapsed_seconds"] = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(2)
          write
        end
      end

      sig { returns(String) }
      def write
        FileUtils.mkdir_p(@dir)
        path = File.join(@dir, "#{name}-#{Time.now.utc.strftime('%Y%m%dT%H%M%SZ')}.json")
        File.write(path, "#{JSON.pretty_generate(@data)}\n")
        $stdout.puts "Recorded #{name}: #{@data['outcome']} in #{@data['elapsed_seconds']}s -> #{path}"
        path
      end
    end
  end
end
