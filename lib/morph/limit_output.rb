#!/usr/bin/env ruby

# This wrapper script runs a command and lets standard out and error flow
# through. However, it does limit the number of lines of output. This is
# used by morph as a wrapper around running scrapers to ensure that they
# can't fill up the docker container log file (and hence the server disk).

require "optparse"
require "open3"

max_lines = nil
command = nil
exit_status = nil

OptionParser.new do |opts|
  opts.banner = "Usage: ./limit_output.rb [max lines] [command to run]"

  max_lines = ARGV[0].to_i
  if ARGV[0].nil?
    STDERR.puts "Please give me the maximum number of lines of output to show"
    puts opts
    exit 1
  end

  command = ARGV[1]
  if command.nil?
    STDERR.puts "Please give me a command to run"
    puts opts
    exit(1)
  end
end.parse!

# Disable output buffering
STDOUT.sync = true
STDERR.sync = true

stdout_buffer = ""
stderr_buffer = ""

line_count = 0

Open3.popen3(command) do |_stdin, stdout, stderr, wait_thr|
  streams = [stdout, stderr]
  until streams.empty?
    IO.select(streams).flatten.compact.each do |io|
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
        (on_stdout_stream ? STDOUT : STDERR) << buffer
      elsif line_count == max_lines
        STDERR.puts "limit_output.rb: Too many lines of output!"
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
    STDOUT << stdout_buffer
    STDERR << stderr_buffer
  end

  exit_status = wait_thr.value.exitstatus
end

exit(exit_status)
