# typed: false
# frozen_string_literal: true

# Capture output of /usr/bin/time command (on Linux)
class Metric < ApplicationRecord
  belongs_to :run, touch: true
  # The names of metrics are all copied from the structure returned by
  # getrusage(2) (with the exception of wall_time)

  # wall_time  Wall clock
  # utime      This is the total amount of time spent executing in user mode,
  #            expressed in a timeval structure (seconds plus microseconds).
  # stime      This is the total amount of time spent executing in kernel mode,
  #            expressed in a timeval structure (seconds plus microseconds).
  # maxrss     This is the maximum resident set size used (in kilobytes). For
  #            RUSAGE_CHILDREN, this is the resident set size of the largest
  #            child, not the maximum resident set size of the process tree.
  # minflt     The number of page faults serviced without any I/O activity;
  #            here I/O activity is avoided by "reclaiming" a page frame from
  #            the list of pages awaiting reallocation.
  # majflt     The number of page faults serviced that required I/O activity.
  # inblock    The number of times the file system had to perform input.
  # oublock    The number of times the file system had to perform output.
  # nvcsw      The number of times a context switch resulted due to a process
  #            voluntarily giving up the processor before its time slice was
  #            completed (usually to await availability of a resource).
  # nivcsw     The number of times a context switch resulted due to a higher
  #            priority process becoming runnable or because the current process
  #            exceeded its time slice.

  def cpu_time
    # At least in development there are some nil utime and stime values
    # So, try to handle this gracefully
    (utime || 0) + (stime || 0)
  end
end
