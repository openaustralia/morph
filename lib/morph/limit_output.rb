#!/usr/bin/env ruby

# This wrapper script runs a command and lets standard out and error flow
# through. However, it does limit the number of lines of output. This is
# used by morph as a wrapper around running scrapers to ensure that they
# can't fill up the docker container log file (and hence the server disk).

require 'optparse'
require 'open3'

command = nil
exit_status = nil

OptionParser.new do |opts|
  opts.banner = 'Usage: ./limit_output.rb [command to run]'

  command = ARGV[0]
  if command.nil?
    STDERR.puts 'Please give me a command to run'
    puts opts
    exit
  end
end.parse!

# Disable output buffering
STDOUT.sync = true
STDERR.sync = true

Open3.popen3(command) do |_stdin, stdout, stderr, wait_thr|
  streams = [stdout, stderr]
  until streams.empty?
    IO.select(streams).flatten.compact.each do |io|
      if io.eof?
        streams.delete io
        next
      end

      # Just send this stuff straight through
      STDOUT << io.readpartial(1024) if io.fileno == stdout.fileno
      STDERR << io.readpartial(1024) if io.fileno == stderr.fileno
    end
  end

  exit_status = wait_thr.value.exitstatus
end

exit(exit_status)
