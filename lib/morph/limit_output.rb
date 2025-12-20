#!/usr/bin/env ruby

# This wrapper script runs a command and lets standard out and error flow
# through. However, it does limit the number of lines of output. This is
# used by morph as a wrapper around running scrapers to ensure that they
# can't fill up the docker container log file (and hence the server disk).

require "optparse"
require "open3"

module Morph
  class LimitOutput
    def self.run(argv, stdout_io: STDOUT, stderr_io: STDERR)
      max_lines = nil
      command = nil
      exit_status = nil

      OptionParser.new do |opts|
        opts.banner = "Usage: ./limit_output.rb [max lines] [command to run]"

        max_lines = argv[0].to_i
        if argv[0].nil?
          stderr_io.puts "Please give me the maximum number of lines of output to show"
          stdout_io.puts opts
          return 1
        end

        command = argv[1]
        if command.nil?
          stderr_io.puts "Please give me a command to run"
          stdout_io.puts opts
          return 1
        end
      end.parse!(argv.dup)

      # Disable output buffering
      stdout_io.sync = true
      stderr_io.sync = true

      stdout_buffer = ""
      stderr_buffer = ""

      line_count = 0

      Open3.popen3(command) do |_stdin, stdout, stderr, wait_thr|
        streams = [stdout, stderr]
        until streams.empty?
          ready = IO.select(streams) || []
          ready.flatten.compact.each do |io|
            if io.eof?
              streams.delete io
              next
            end

            on_stdout_stream = io.fileno == stdout.fileno
            # Just send this stuff straight through
            buffer = on_stdout_stream ? stdout_buffer : stderr_buffer
            s = io.readpartial(1)
            buffer << s
            next unless s == "\n"

            if line_count < max_lines || max_lines.zero?
              (on_stdout_stream ? stdout_io : stderr_io) << buffer
            elsif line_count == max_lines
              stderr_io.puts "limit_output.rb: Too many lines of output!"
            end
            if on_stdout_stream
              stdout_buffer = ""
            else
              stderr_buffer = ""
            end
            line_count += 1
          end
        end

        # Output whatever is left in the buffers
        if line_count < max_lines || max_lines.zero?
          stdout_io << stdout_buffer
          stderr_io << stderr_buffer
        end

        exit_status = wait_thr.value.exitstatus
      end

      exit_status
    end
  end
end

exit(Morph::LimitOutput.run(ARGV) || 2) if __FILE__ == $0
