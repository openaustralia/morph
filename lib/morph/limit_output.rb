#!/usr/bin/env ruby

require "optparse"
require "open3"

# NOTE: This script MUST be compatible with ruby 1.9 through to current versions - do NOT modernize it!

module Morph

  # This wrapper script runs a command and lets standard out and error flow
  # through. However, it does limit the number of lines of output. Morph
  # uses this as a wrapper around running scrapers to ensure that they
  # can't fill up the docker container log file (and hence the server disk)

  class LimitOutput
    USAGE = "Usage: ./limit_output.rb max_lines command_to_run"

    def self.run(args, options = {})
      stdout_io = options.fetch(:stdout_io, $stdout)
      stderr_io = options.fetch(:stderr_io, $stderr)
      args = OptionParser.new do |opts|
        opts.banner = USAGE
        if args.length.zero?
          stderr_io.puts "Please give me the maximum number of lines"
        elsif args.length == 1
          stderr_io.puts "Please give me a command to run"
        elsif args.length > 2
          stderr_io.puts "Please give me the command to run as one argument"
        end
        if args.length < 2
          stderr_io.puts opts
          return 1
        end
      end.parse(args)

      max_lines = args[0].to_i
      command = args[1]

      # Disable output buffering
      stdout_io.sync = true
      stderr_io.sync = true

      stdout_buffer = ""
      stderr_buffer = ""

      line_count = 0

      exit_status = 1
      Open3.popen3(command) do |_stdin_pipe, stdout_pipe, stderr_pipe, wait_thr|
        streams = [stdout_pipe, stderr_pipe]
        until streams.empty?
          IO.select(streams).flatten.compact.each do |io|
            if io.eof?
              streams.delete io
              next
            end

            on_stdout_stream = io.fileno == stdout_pipe.fileno
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

        process_status = wait_thr.value
        exit_status = process_status.exited? ? process_status.exitstatus : process_status.termsig + 128
      end

      exit_status
    end
  end
end

exit Morph::LimitOutput.run(ARGV) if __FILE__ == $0

