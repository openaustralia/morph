# typed: strict
# frozen_string_literal: true

module Morph
  class TimeCommand
    extend T::Sig

    sig { params(other: T::Array[String], metric_file: String).returns(T::Array[String]) }
    def self.command(other, metric_file)
      ["/usr/bin/time", "-v", "-o", metric_file] + other
    end

    # Parse the output of the time command and return a hash of the parameters
    sig { params(string: String).returns(T::Hash[Symbol, T.untyped]) }
    def self.params_from_string(string)
      params = string.split("\n").inject({}) do |p, line|
        r = parse_line(line)
        p.merge(r ? { r[0] => r[1] } : {})
      end
      # There's a bug in GNU time 1.7 which wrongly reports the maximum resident
      # set size on the version of Ubuntu that we're using.
      # See https://groups.google.com/forum/#!topic/gnu.utils.help/u1MOsHL4bhg
      # Let's fix it up
      # If we can't get the page size we can't really figure out maxrss
      params[:maxrss] = (params[:maxrss] * 1024 / params[:page_size] if params[:page_size])

      # page_size isn't an attribute on this model
      params.delete(:page_size)
      params
    end

    sig { params(line: String).returns(T.nilable([Symbol, T.untyped])) }
    def self.parse_line(line)
      field, value = line.split(": ")

      case field
      when /Maximum resident set size \(kbytes\)/
        [:maxrss, value.to_i]
      when /Minor \(reclaiming a frame\) page faults/
        [:minflt, value.to_i]
      when %r{Major \(requiring I/O\) page faults}
        [:majflt, value.to_i]
      when /User time \(seconds\)/
        [:utime, value.to_f]
      when /System time \(seconds\)/
        [:stime, value.to_f]
      when /Elapsed \(wall clock\) time \(h:mm:ss or m:ss\)/
        raise "Unexpected format for line" if value.nil?

        n = value.split(":").map(&:to_f)
        case n.count
        when 2
          h = 0
          m = T.must(n[0])
          s = T.must(n[1])
        when 3
          h = T.must(n[0])
          m = T.must(n[1])
          s = T.must(n[2])
        else
          raise "Unexpected format for wall clock"
        end
        [:wall_time, (((h * 60) + m) * 60) + s]
      when /File system inputs/
        [:inblock, value.to_i]
      when /File system outputs/
        [:oublock, value.to_i]
      when /Voluntary context switches/
        [:nvcsw, value.to_i]
      when /Involuntary context switches/
        [:nivcsw, value.to_i]
      when /Page size \(bytes\)/
        [:page_size, value.to_i]
      end
    end
  end
end
