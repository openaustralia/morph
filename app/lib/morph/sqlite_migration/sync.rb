# typed: strict
# frozen_string_literal: true

require "json"
require "open3"
require "shellwords"

module Morph
  module SqliteMigration
    # Copies the scraper SQLite databases and repos (db/scrapers) from the old
    # server to the new one with rsync, for the bulk copy days ahead of cutover
    # and again for the final delta inside the window (#1589).
    #
    # Nothing here holds a credential. Source and destination are
    # `[user@host:]/path` arguments and authentication is whatever ssh already
    # has (an agent or a key named in `ssh_command`). Re-running after an
    # interruption resumes, because rsync skips files that already match and
    # --inplace carries on from what a half-copied file already has.
    class Sync
      extend T::Sig

      CREDENTIALS_IN_URL = %r{\A(?:rsync://)?[^/@\s:]+:[^/@\s]*@}
      # rsync exits 24 when files vanish between listing and copying
      VANISHED = 24

      class Error < StandardError; end

      FAILURE_HINTS = T.let(
        { 23 => " (some files could not be copied)", 25 => " (stopped by max_delete, so more files were due for deletion than allowed)" }.freeze,
        T::Hash[Integer, String]
      )

      # Whole numbers only, so a typo cannot silently become 0, which rsync reads as "no limit"
      sig { params(name: String, value: T.nilable(String)).returns(T.nilable(Integer)) }
      def self.positive_integer(name, value)
        return nil if value.nil? || value.strip.empty?

        number = T.let(Integer(value, exception: false), T.nilable(Integer))
        raise Error, "#{name} must be a whole number above 0" if number.nil? || number < 1

        number
      end

      class Result < T::Struct
        extend T::Sig

        const :mode, Symbol
        const :source, String
        const :destination, String
        const :exit_status, Integer
        const :elapsed_seconds, Float
        const :files_transferred, T.nilable(Integer)
        const :file_bytes, T.nilable(Integer)
        const :wire_bytes, T.nilable(Integer)
        const :total_file_bytes, T.nilable(Integer)
        const :warning, T.nilable(String)
        const :dry_run, T::Boolean

        sig { returns(T.nilable(Float)) }
        def bytes_per_second
          bytes = wire_bytes
          return nil if bytes.nil? || elapsed_seconds <= 0

          bytes / elapsed_seconds
        end

        sig { returns(String) }
        def summary
          speed = bytes_per_second
          [
            "Mode:            #{mode}#{' (dry run, nothing copied)' if dry_run}",
            "Elapsed:         #{elapsed_seconds.round(1)} s",
            "Files copied:    #{files_transferred || 'unknown'}",
            "Bytes on wire:   #{wire_bytes || 'unknown'}",
            "Transfer speed:  #{speed ? format('%.1f MB/s', speed / 1_000_000) : 'unknown'}",
            *(warning ? ["Warning:         #{warning}"] : [])
          ].join("\n")
        end

        sig { returns(T::Hash[Symbol, T.untyped]) }
        def to_record
          {
            recorded_at: Time.now.utc.iso8601, mode: mode, dry_run: dry_run, source: source, destination: destination,
            exit_status: exit_status, elapsed_seconds: elapsed_seconds.round(1),
            files_transferred: files_transferred, file_bytes: file_bytes, wire_bytes: wire_bytes,
            total_file_bytes: total_file_bytes, bytes_per_second: bytes_per_second&.round, warning: warning
          }
        end
      end

      Runner = T.type_alias { T.proc.params(argv: T::Array[String], on_line: T.proc.params(line: String).void).returns(Integer) }

      DEFAULT_RUNNER = T.let(
        lambda do |argv, on_line|
          status = T.let(nil, T.nilable(Process::Status))
          Open3.popen2e(*argv) do |stdin, out, wait|
            stdin.close
            out.each_line { |line| on_line.call(line) }
            status = wait.value
          end
          status&.exitstatus || 1
        end,
        Runner
      )

      sig do
        params(
          source: String, destination: String, mode: Symbol, delete: T::Boolean, max_delete: T.nilable(Integer),
          bwlimit: T.nilable(Integer), ssh_command: T.nilable(String), dry_run: T::Boolean, runner: Runner
        ).void
      end
      def initialize(source:, destination:, mode:, delete: false, max_delete: nil, bwlimit: nil,
                     ssh_command: nil, dry_run: false, runner: DEFAULT_RUNNER)
        raise Error, "mode must be bulk or delta" unless %i[bulk delta].include?(mode)
        raise Error, "source is required" if source.strip.empty?
        raise Error, "destination is required" if destination.strip.empty?

        [source, destination].each do |location|
          raise Error, "do not put a password in a location, use ssh keys or an agent" if location.match?(CREDENTIALS_IN_URL)
        end
        raise Error, "delete needs max_delete, so a wrong source cannot empty the destination" if delete && max_delete.nil?

        # A trailing slash copies the contents, not a nested scrapers/scrapers
        @source = T.let(with_trailing_slash(source), String)
        @destination = T.let(with_trailing_slash(destination), String)
        @mode = mode
        @delete = delete
        @max_delete = max_delete
        @bwlimit = bwlimit
        @ssh_command = ssh_command
        @dry_run = dry_run
        @runner = runner
      end

      sig { returns(T::Array[String]) }
      def command
        argv = %w[rsync -a --inplace --stats]
        argv << "--dry-run" if @dry_run
        argv << "--bwlimit=#{@bwlimit}" if @bwlimit
        argv.push("-e", @ssh_command) if @ssh_command
        argv.push("--delete", "--max-delete=#{@max_delete}") if @delete
        argv.push(@source, @destination)
      end

      # The command with any user@ removed, safe to print and log
      sig { returns(String) }
      def display_command
        command.map { |arg| [@source, @destination].include?(arg) ? self.class.scrub(arg) : arg }.shelljoin
      end

      sig { params(on_line: T.nilable(T.proc.params(line: String).void)).returns(Result) }
      def run(&on_line)
        output = T.let([], T::Array[String])
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC).to_f
        status = begin
          @runner.call(command, lambda do |line|
            output << line
            on_line&.call(line)
          end)
        rescue SystemCallError => e
          raise Error, "could not run rsync (is it installed?): #{e.message}"
        end
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC).to_f - started
        build_result(status, elapsed, output.join)
      end

      sig { params(text: String).returns(T::Hash[Symbol, Integer]) }
      def self.parse_stats(text)
        {
          files_transferred: stat(text, /Number of (?:regular )?files transferred: ([\d,.]+)/),
          file_bytes: stat(text, /Total transferred file size: ([\d,.]+)/),
          total_file_bytes: stat(text, /Total file size: ([\d,.]+)/),
          sent: stat(text, /Total bytes sent: ([\d,.]+)/),
          received: stat(text, /Total bytes received: ([\d,.]+)/)
        }.compact
      end

      sig { params(text: String, pattern: Regexp).returns(T.nilable(Integer)) }
      def self.stat(text, pattern)
        match = text.match(pattern)
        match && match[1]&.delete(",.")&.to_i
      end

      # Keeps the host and path, drops any user@ so a log never names a login
      sig { params(location: String).returns(String) }
      def self.scrub(location)
        location.sub(%r{\A[^/@\s]+@}, "")
      end

      private

      sig { params(location: String).returns(String) }
      def with_trailing_slash(location)
        location.end_with?("/") ? location : "#{location}/"
      end

      sig { params(status: Integer, elapsed: Float, output: String).returns(Result) }
      def build_result(status, elapsed, output)
        warning = nil
        if status == VANISHED && @mode == :bulk
          warning = "some files vanished during the copy, which is normal while scrapers run; the delta pass picks up the rest"
        elsif status != 0
          raise Error, "rsync exited with status #{status}#{FAILURE_HINTS.fetch(status, '')}. Last output: #{output.lines.last(3).join.strip}"
        end

        stats = self.class.parse_stats(output)
        sent = stats[:sent]
        received = stats[:received]
        wire = sent && received ? sent + received : nil
        Result.new(
          mode: @mode, source: self.class.scrub(@source), destination: self.class.scrub(@destination),
          exit_status: status, elapsed_seconds: elapsed, files_transferred: stats[:files_transferred],
          file_bytes: stats[:file_bytes], wire_bytes: wire, total_file_bytes: stats[:total_file_bytes],
          warning: warning, dry_run: @dry_run
        )
      end
    end
  end
end
