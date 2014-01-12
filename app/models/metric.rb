# Capture output of /usr/bin/time command (on Linux)
class Metric < ActiveRecord::Base
  # The names of metrics are all copied from the structure returned by getrusage(2) (with the exception of wall_time) 

  # wall_time  Wall clock
  # utime      This is the total amount of time spent executing in user mode, expressed
  #            in a timeval structure (seconds plus microseconds).
  # stime      This is the total amount of time spent executing in kernel mode, expressed
  #            in a timeval structure (seconds plus microseconds).
  # maxrss     This is the maximum resident set size used (in kilobytes). For RUSAGE_CHILDREN,
  #            this is the resident set size of the largest child, not the maximum resident
  #            set size of the process tree.
  # minflt     The number of page faults serviced without any I/O activity; here I/O activity
  #            is avoided by "reclaiming" a page frame from the list of pages awaiting reallocation.
  # majflt     The number of page faults serviced that required I/O activity.
  # inblock    The number of times the file system had to perform input.
  # oublock    The number of times the file system had to perform output.
  # nvcsw      The number of times a context switch resulted due to a process voluntarily giving
  #            up the processor before its time slice was completed (usually to await availability
  #            of a resource).
  # nivcsw     The number of times a context switch resulted due to a higher priority process
  #            becoming runnable or because the current process exceeded its time slice.

  def cpu_time
    utime + stime
  end
  
  def self.command(other, metric_file)
    "/usr/bin/time -v -o #{metric_file} #{other}"
  end

  def self.read_from_string(s)
    params = s.split("\n").inject({}) do |params, line|
      r = parse_line(line)
      params.merge(r ? {r[0] => r[1]} : {})
    end
    # There's a bug in GNU time 1.7 which wrongly reports the maximum resident set size on the version of Ubuntu that we're using
    # See https://groups.google.com/forum/#!topic/gnu.utils.help/u1MOsHL4bhg
    # Let's fix it up
    raise "Page size not known" unless params[:page_size]
    params[:maxrss] = params[:maxrss] * 1024 / params[:page_size]

    # page_size isn't an attribute on this model
    params.delete(:page_size)
    Metric.create(params)
  end

  def self.read_from_file(file)
    read_from_string(File.read(file))
  end

  def self.parse_line(l)
    field, value = l.split(": ")
    case field
    when /Maximum resident set size \(kbytes\)/
      [:maxrss, value.to_i]
    when /Minor \(reclaiming a frame\) page faults/
      [:minflt, value.to_i]
    when /Major \(requiring I\/O\) page faults/
      [:majflt, value.to_i]
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
    when /Page size \(bytes\)/
      [:page_size, value.to_i]
    end
  end
end
