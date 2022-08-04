# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `posix-spawn` gem.
# Please instead update this file by running `bin/tapioca gem posix-spawn`.

# @private
#
# source://posix-spawn-0.3.15/lib/posix/spawn.rb:8
class IO
  include ::Enumerable
  include ::File::Constants
end

class IO::ConsoleMode
  def echo=(_arg0); end
  def raw(*_arg0); end
  def raw!(*_arg0); end

  private

  def initialize_copy(_arg0); end
end

class IO::EAGAINWaitReadable < ::Errno::EAGAIN
  include ::IO::WaitReadable
end

class IO::EAGAINWaitWritable < ::Errno::EAGAIN
  include ::IO::WaitWritable
end

class IO::EINPROGRESSWaitReadable < ::Errno::EINPROGRESS
  include ::IO::WaitReadable
end

class IO::EINPROGRESSWaitWritable < ::Errno::EINPROGRESS
  include ::IO::WaitWritable
end

IO::EWOULDBLOCKWaitReadable = IO::EAGAINWaitReadable
IO::EWOULDBLOCKWaitWritable = IO::EAGAINWaitWritable

# source://posix-spawn-0.3.15/lib/posix/spawn/version.rb:1
module POSIX; end

# The POSIX::Spawn module implements a compatible subset of Ruby 1.9's
# Process::spawn and related methods using the IEEE Std 1003.1 posix_spawn(2)
# system interfaces where available, or a pure Ruby fork/exec based
# implementation when not.
#
# In Ruby 1.9, a versatile new process spawning interface was added
# (Process::spawn) as the foundation for enhanced versions of existing
# process-related methods like Kernel#system, Kernel#`, and IO#popen. These
# methods are backward compatible with their Ruby 1.8 counterparts but
# support a large number of new options. The POSIX::Spawn module implements
# many of these methods with support for most of Ruby 1.9's features.
#
# The argument signatures for all of these methods follow a new convention,
# making it possible to take advantage of Process::spawn features:
#
#   spawn([env], command, [argv1, ...], [options])
#   system([env], command, [argv1, ...], [options])
#   popen([[env], command, [argv1, ...]], mode="r", [options])
#
# The env, command, and options arguments are described below.
#
# == Environment
#
# If a hash is given in the first argument (env), the child process's
# environment becomes a merge of the parent's and any modifications
# specified in the hash. When a value in env is nil, the variable is
# unset in the child:
#
#     # set FOO as BAR and unset BAZ.
#     spawn({"FOO" => "BAR", "BAZ" => nil}, 'echo', 'hello world')
#
# == Command
#
# The command and optional argvN string arguments specify the command to
# execute and any program arguments. When only command is given and
# includes a space character, the command text is executed by the system
# shell interpreter, as if by:
#
#     /bin/sh -c 'command'
#
# When command does not include a space character, or one or more argvN
# arguments are given, the command is executed as if by execve(2) with
# each argument forming the new program's argv.
#
# NOTE: Use of the shell variation is generally discouraged unless you
# indeed want to execute a shell program. Specifying an explicitly argv is
# typically more secure and less error prone in most cases.
#
# == Options
#
# When a hash is given in the last argument (options), it specifies a
# current directory and zero or more fd redirects for the child process.
#
# The :chdir option specifies the current directory. Note that :chdir is not
# thread-safe on systems that provide posix_spawn(2), because it forces a
# temporary change of the working directory of the calling process.
#
#     spawn(command, :chdir => "/var/tmp")
#
# The :in, :out, :err, an Integer, an IO object or an Array option specify
# fd redirection. For example, stderr can be merged into stdout as follows:
#
#     spawn(command, :err => :out)
#     spawn(command, 2 => 1)
#     spawn(command, STDERR => :out)
#     spawn(command, STDERR => STDOUT)
#
# The key is a fd in the newly spawned child process (stderr in this case).
# The value is a fd in the parent process (stdout in this case).
#
# You can also specify a filename for redirection instead of an fd:
#
#     spawn(command, :in => "/dev/null")   # read mode
#     spawn(command, :out => "/dev/null")  # write mode
#     spawn(command, :err => "log")        # write mode
#     spawn(command, 3 => "/dev/null")     # read mode
#
# When redirecting to stdout or stderr, the files are opened in write mode;
# otherwise, read mode is used.
#
# It's also possible to control the open flags and file permissions
# directly by passing an array value:
#
#     spawn(command, :in=>["file"])       # read mode assumed
#     spawn(command, :in=>["file", "r"])  # explicit read mode
#     spawn(command, :out=>["log", "w"])  # explicit write mode, 0644 assumed
#     spawn(command, :out=>["log", "w", 0600])
#     spawn(command, :out=>["log", File::APPEND | File::CREAT, 0600])
#
# The array is a [filename, open_mode, perms] tuple. open_mode can be a
# string or an integer. When open_mode is omitted or nil, File::RDONLY is
# assumed. The perms element should be an integer. When perms is omitted or
# nil, 0644 is assumed.
#
# The :close It's possible to direct an fd be closed in the child process.  This is
# important for implementing `popen`-style logic and other forms of IPC between
# processes using `IO.pipe`:
#
#     rd, wr = IO.pipe
#     pid = spawn('echo', 'hello world', rd => :close, :stdout => wr)
#     wr.close
#     output = rd.read
#     Process.wait(pid)
#
# == Spawn Implementation
#
# The POSIX::Spawn#spawn method uses the best available implementation given
# the current platform and Ruby version. In order of preference, they are:
#
#  1. The posix_spawn based C extension method (pspawn).
#  2. Process::spawn when available (Ruby 1.9 only).
#  3. A simple pure-Ruby fork/exec based spawn implementation compatible
#     with Ruby >= 1.8.7.
#
# source://posix-spawn-0.3.15/lib/posix/spawn/version.rb:2
module POSIX::Spawn
  extend ::POSIX::Spawn

  def _pspawn(_arg0, _arg1, _arg2); end

  # Executes a command in a subshell using the system's shell interpreter
  # and returns anything written to the new process's stdout. This method
  # is compatible with Kernel#`.
  #
  # Returns the String output of the command.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn.rb:279
  def `(cmd); end

  # Spawn a child process with a variety of options using a pure
  # Ruby fork + exec. Supports the standard spawn interface as described in
  # the POSIX::Spawn module documentation.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn.rb:195
  def fspawn(*args); end

  # Spawn a child process with all standard IO streams piped in and out of
  # the spawning process. Supports the standard spawn interface as described
  # in the POSIX::Spawn module documentation.
  #
  # Returns a [pid, stdin, stdout, stderr] tuple, where pid is the new
  # process's pid, stdin is a writeable IO object, and stdout / stderr are
  # readable IO objects. The caller should take care to close all IO objects
  # when finished and the child process's status must be collected by a call
  # to Process::waitpid or equivalent.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn.rb:305
  def popen4(*argv); end

  # Spawn a child process with a variety of options using the posix_spawn(2)
  # systems interfaces. Supports the standard spawn interface as described in
  # the POSIX::Spawn module documentation.
  #
  # Raises NotImplementedError when the posix_spawn_ext module could not be
  # loaded due to lack of platform support.
  #
  # @raise [NotImplementedError]
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn.rb:176
  def pspawn(*args); end

  # Spawn a child process with a variety of options using the best
  # available implementation for the current platform and Ruby version.
  #
  # spawn([env], command, [argv1, ...], [options])
  #
  # env     - Optional hash specifying the new process's environment.
  # command - A string command name, or shell program, used to determine the
  #           program to execute.
  # argvN   - Zero or more string program arguments (argv).
  # options - Optional hash of operations to perform before executing the
  #           new child process.
  #
  # Returns the integer pid of the newly spawned process.
  # Raises any number of Errno:: exceptions on failure.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn.rb:160
  def spawn(*args); end

  # Executes a command and waits for it to complete. The command's exit
  # status is available as $?. Supports the standard spawn interface as
  # described in the POSIX::Spawn module documentation.
  #
  # This method is compatible with Kernel#system.
  #
  # Returns true if the command returns a zero exit status, or false for
  # non-zero exit.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn.rb:265
  def system(*args); end

  private

  # Converts the various supported command argument variations into a
  # standard argv suitable for use with exec. This includes detecting commands
  # to be run through the shell (single argument strings with spaces).
  #
  # The args array may follow any of these variations:
  #
  # 'true'                     => [['true', 'true']]
  # 'echo', 'hello', 'world'   => [['echo', 'echo'], 'hello', 'world']
  # 'echo hello world'         => [['/bin/sh', '/bin/sh'], '-c', 'echo hello world']
  # ['echo', 'fuuu'], 'hello'  => [['echo', 'fuuu'], 'hello']
  #
  # Returns a [[cmdname, argv0], argv1, ...] array.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn.rb:531
  def adjust_process_spawn_argv(args); end

  # The default [file, flags, mode] tuple for a given fd and filename. The
  # default flags vary based on the what fd is being redirected. stdout and
  # stderr default to write, while stdin and all other fds default to read.
  #
  # fd   - The file descriptor that is being redirected. This may be an IO
  #        object, integer fd number, or :in, :out, :err for one of the standard
  #        streams.
  # file - The string path to the file that fd should be redirected to.
  #
  # Returns a [file, flags, mode] tuple.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn.rb:448
  def default_file_reopen_info(fd, file); end

  # Turns the various varargs incantations supported by Process::spawn into a
  # simple [env, argv, options] tuple. This just makes life easier for the
  # extension functions.
  #
  # The following method signature is supported:
  #   Process::spawn([env], command, ..., [options])
  #
  # The env and options hashes are optional. The command may be a variable
  # number of strings or an Array full of strings that make up the new process's
  # argv.
  #
  # Returns an [env, argv, options] tuple. All elements are guaranteed to be
  # non-nil. When no env or options are given, empty hashes are returned.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn.rb:355
  def extract_process_spawn_arguments(*args); end

  # Determine whether object is fd-like.
  #
  # Returns true if object is an instance of IO, Integer >= 0, or one of the
  # the symbolic names :in, :out, or :err.
  #
  # @return [Boolean]
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn.rb:465
  def fd?(object); end

  # Convert a fd identifier to an IO object.
  #
  # Returns nil or an instance of IO.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn.rb:479
  def fd_to_io(object); end

  # Convert { [fd1, fd2, ...] => (:close|fd) } options to individual keys,
  # like: { fd1 => :close, fd2 => :close }. This just makes life easier for the
  # spawn implementations.
  #
  # options - The options hash. This is modified in place.
  #
  # Returns the modified options hash.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn.rb:389
  def flatten_process_spawn_options!(options); end

  # Convert variations of redirecting to a file to a standard tuple.
  #
  # :in   => '/some/file'   => ['/some/file', 'r', 0644]
  # :out  => '/some/file'   => ['/some/file', 'w', 0644]
  # :err  => '/some/file'   => ['/some/file', 'w', 0644]
  # STDIN => '/some/file'   => ['/some/file', 'r', 0644]
  #
  # Returns the modified options hash.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn.rb:416
  def normalize_process_spawn_redirect_file_options!(options); end

  # Derives the shell command to use when running the spawn.
  #
  # On a Windows machine, this will yield:
  #   [['cmd.exe', 'cmd.exe'], '/c']
  # Note: 'cmd.exe' is used if the COMSPEC environment variable
  #   is not specified. If you would like to use something other
  #   than 'cmd.exe', specify its path in ENV['COMSPEC']
  #
  # On all other systems, this will yield:
  #   [['/bin/sh', '/bin/sh'], '-c']
  #
  # Returns a platform-specific [[<shell>, <shell>], <command-switch>] array.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn.rb:510
  def system_command_prefixes; end
end

# POSIX::Spawn::Child includes logic for executing child processes and
# reading/writing from their standard input, output, and error streams. It's
# designed to take all input in a single string and provides all output
# (stderr and stdout) as single strings and is therefore not well-suited
# to streaming large quantities of data in and out of commands.
#
# Create and run a process to completion:
#
#   >> child = POSIX::Spawn::Child.new('git', '--help')
#
# Retrieve stdout or stderr output:
#
#   >> child.out
#   => "usage: git [--version] [--exec-path[=GIT_EXEC_PATH]]\n ..."
#   >> child.err
#   => ""
#
# Check process exit status information:
#
#   >> child.status
#   => #<Process::Status: pid=80718,exited(0)>
#
# To write data on the new process's stdin immediately after spawning:
#
#   >> child = POSIX::Spawn::Child.new('bc', :input => '40 + 2')
#   >> child.out
#   "42\n"
#
# To access output from the process even if an exception was raised:
#
#   >> child = POSIX::Spawn::Child.build('git', 'log', :max => 1000)
#   >> begin
#   ?>   child.exec!
#   ?> rescue POSIX::Spawn::MaximumOutputExceeded
#   ?>   # just so you know
#   ?> end
#   >> child.out
#   "... first 1000 characters of log output ..."
#
# Q: Why use POSIX::Spawn::Child instead of popen3, hand rolled fork/exec
# code, or Process::spawn?
#
# - It's more efficient than popen3 and provides meaningful process
#   hierarchies because it performs a single fork/exec. (popen3 double forks
#   to avoid needing to collect the exit status and also calls
#   Process::detach which creates a Ruby Thread!!!!).
#
# - It handles all max pipe buffer (PIPE_BUF) hang cases when reading and
#   writing semi-large amounts of data. This is non-trivial to implement
#   correctly and must be accounted for with popen3, spawn, or hand rolled
#   fork/exec code.
#
# - It's more portable than hand rolled pipe, fork, exec code because
#   fork(2) and exec aren't available on all platforms. In those cases,
#   POSIX::Spawn::Child falls back to using whatever janky substitutes
#   the platform provides.
#
# source://posix-spawn-0.3.15/lib/posix/spawn/child.rb:59
class POSIX::Spawn::Child
  include ::POSIX::Spawn

  # Spawn a new process, write all input and read all output, and wait for
  # the program to exit. Supports the standard spawn interface as described
  # in the POSIX::Spawn module documentation:
  #
  #   new([env], command, [argv1, ...], [options])
  #
  # The following options are supported in addition to the standard
  # POSIX::Spawn options:
  #
  #   :input   => str      Write str to the new process's standard input.
  #   :timeout => int      Maximum number of seconds to allow the process
  #                        to execute before aborting with a TimeoutExceeded
  #                        exception.
  #   :max     => total    Maximum number of bytes of output to allow the
  #                        process to generate before aborting with a
  #                        MaximumOutputExceeded exception.
  #   :pgroup_kill => bool Boolean specifying whether to kill the process
  #                        group (true) or individual process (false, default).
  #                        Setting this option true implies :pgroup => true.
  #
  # Returns a new Child instance whose underlying process has already
  # executed to completion. The out, err, and status attributes are
  # immediately available.
  #
  # @return [Child] a new instance of Child
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn/child.rb:85
  def initialize(*args); end

  # All data written to the child process's stderr stream as a String.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn/child.rb:128
  def err; end

  # Execute command, write input, and read output. This is called
  # immediately when a new instance of this object is created, or
  # can be called explicitly when creating the Child via `build`.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn/child.rb:149
  def exec!; end

  # All data written to the child process's stdout stream as a String.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn/child.rb:125
  def out; end

  # The pid of the spawned child process. This is unlikely to be a valid
  # current pid since Child#exec! doesn't return until the process finishes
  # and is reaped.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn/child.rb:139
  def pid; end

  # Total command execution time (wall-clock time)
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn/child.rb:134
  def runtime; end

  # A Process::Status object with information on how the child exited.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn/child.rb:131
  def status; end

  # Determine if the process did exit with a zero exit status.
  #
  # @return [Boolean]
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn/child.rb:142
  def success?; end

  private

  # Start a select loop writing any input on the child's stdin and reading
  # any output from the child's stdout or stderr.
  #
  # input   - String input to write on stdin. May be nil.
  # stdin   - The write side IO object for the child's stdin stream.
  # stdout  - The read side IO object for the child's stdout stream.
  # stderr  - The read side IO object for the child's stderr stream.
  # timeout - An optional Numeric specifying the total number of seconds
  #           the read/write operations should occur for.
  #
  # Returns an [out, err] tuple where both elements are strings with all
  #   data written to the stdout and stderr streams, respectively.
  # Raises TimeoutExceeded when all data has not been read / written within
  #   the duration specified in the timeout argument.
  # Raises MaximumOutputExceeded when the total number of bytes output
  #   exceeds the amount specified by the max argument.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn/child.rb:195
  def read_and_write(input, stdin, stdout, stderr, timeout = T.unsafe(nil), max = T.unsafe(nil)); end

  # Wait for the child process to exit
  #
  # Returns the Process::Status object obtained by reaping the process.
  #
  # source://posix-spawn-0.3.15/lib/posix/spawn/child.rb:274
  def waitpid(pid); end

  class << self
    # Set up a new process to spawn, but do not actually spawn it.
    #
    # Invoke this just like the normal constructor to set up a process
    # to be run.  Call `exec!` to actually run the child process, send
    # the input, read the output, and wait for completion.  Use this
    # alternative way of constructing a POSIX::Spawn::Child if you want
    # to read any partial output from the child process even after an
    # exception.
    #
    #   child = POSIX::Spawn::Child.build(... arguments ...)
    #   child.exec!
    #
    # The arguments are the same as the regular constructor.
    #
    # Returns a new Child instance but does not run the underlying process.
    #
    # source://posix-spawn-0.3.15/lib/posix/spawn/child.rb:114
    def build(*args); end
  end
end

# Maximum buffer size for reading
#
# source://posix-spawn-0.3.15/lib/posix/spawn/child.rb:177
POSIX::Spawn::Child::BUFSIZE = T.let(T.unsafe(nil), Integer)

# Exception raised when the total number of bytes output on the command's
# stderr and stdout streams exceeds the maximum output size (:max option).
# Currently
#
# source://posix-spawn-0.3.15/lib/posix/spawn.rb:333
class POSIX::Spawn::MaximumOutputExceeded < ::StandardError; end

# Mapping of string open modes to integer oflag versions.
#
# source://posix-spawn-0.3.15/lib/posix/spawn.rb:399
POSIX::Spawn::OFLAGS = T.let(T.unsafe(nil), Hash)

# Exception raised when timeout is exceeded.
#
# source://posix-spawn-0.3.15/lib/posix/spawn.rb:337
class POSIX::Spawn::TimeoutExceeded < ::StandardError; end

# source://posix-spawn-0.3.15/lib/posix/spawn/version.rb:3
POSIX::Spawn::VERSION = T.let(T.unsafe(nil), String)
