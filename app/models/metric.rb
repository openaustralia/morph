# Capture output of /usr/bin/time command (on Linux)
class Metric < ActiveRecord::Base
  # The names of metrics are all copied from the structure returned by getrusage(2) (with the exception of wall_time) 

  # wall_time
  # Elapsed (wall clock) time (h:mm:ss or m:ss): 0:00.02
  # Wall clock

  # utime
  # User time (seconds): 0.00
  # This is the total amount of time spent executing in user mode, expressed in a timeval structure (seconds plus microseconds).

  # stime
  # System time (seconds): 0.00
  # This is the total amount of time spent executing in kernel mode, expressed in a timeval structure (seconds plus microseconds).

  # maxrss (since Linux 2.6.32)
  # Maximum resident set size (kbytes): 4208
  # This is the maximum resident set size used (in kilobytes). For RUSAGE_CHILDREN, this is the resident set size of the largest child, not the maximum resident set size of the process tree.

  # minflt
  # Minor (reclaiming a frame) page faults: 312
  # The number of page faults serviced without any I/O activity; here I/O activity is avoided by "reclaiming" a page frame from the list of pages awaiting reallocation.

  # majflt
  # Major (requiring I/O) page faults: 2
  # The number of page faults serviced that required I/O activity.

  # inblock (since Linux 2.6.22)
  # File system inputs: 480
  # The number of times the file system had to perform input.

  # oublock (since Linux 2.6.22)
  # File system outputs: 0
  # The number of times the file system had to perform output.

  # nvcsw (since Linux 2.6)
  # Voluntary context switches: 43
  # The number of times a context switch resulted due to a process voluntarily giving up the processor before its time slice was completed (usually to await availability of a resource).

  # nivcsw (since Linux 2.6)
  # Involuntary context switches: 65
  # The number of times a context switch resulted due to a higher priority process becoming runnable or because the current process exceeded its time slice.

  def self.command(other, metric_file)
    "/usr/bin/time -v -o #{metric_file} #{other}"
  end

  def self.read_from_string(s)
    params = s.split("\n").inject({}) do |params, line|
      r = parse_line(line)
      params.merge({r[0] => r[1]})
    end
    Metric.new(params)
  end

  def self.parse_line(l)
    field, value = l.split(": ")
    case field
    when /Maximum resident set size \(kbytes\)/
      [:maxrss, value.to_i]
    when /Minor \(reclaiming a frame\) page faults/
      [:minflt, value.to_i]
    when /Major \(requiring I\/O\) page faults/
      [:maxflt, value.to_i]
    when /User time \(seconds\)/
      [:utime, value.to_f]
    when /System time \(seconds\)/
      [:stime, value.to_f]
    when /Elapsed \(wall clock\) time \(h:mm:ss or m:ss\)/
      n = value.split(":").map{|v| v.to_f}
      if n.count == 2
        m, s = n
        h = 0
      elsif n.count == 3
        h, m, s = n
      end
      [:wall_time, (h * 60 + m) * 60 + s ]
    when /File system inputs/
      [:inblock, value.to_i]
    when /File system outputs/
      [:oublock, value.to_i]
    when /Voluntary context switches/
      [:nvcsw, value.to_i]
    when /Involuntary context switches/
      [:nivcsw, value.to_i]
    end
  end
end
