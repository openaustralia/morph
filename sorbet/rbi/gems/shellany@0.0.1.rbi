# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `shellany` gem.
# Please instead update this file by running `bin/tapioca gem shellany`.

# source://shellany-0.0.1/lib/shellany/sheller.rb:3
module Shellany; end

# The Guard sheller abstract the actual subshell
# calls and allow easier stubbing.
#
# source://shellany-0.0.1/lib/shellany/sheller.rb:7
class Shellany::Sheller
  # Creates a new Guard::Sheller object.
  #
  # @param args [String] a command to run in a subshell
  # @param args [Array<String>] an array of command parts to run in a subshell
  # @param args [*String] a list of command parts to run in a subshell
  # @return [Sheller] a new instance of Sheller
  #
  # source://shellany-0.0.1/lib/shellany/sheller.rb:16
  def initialize(*args); end

  # Returns true if the command succeeded, false otherwise.
  #
  # @return [Boolean] whether or not the command succeeded
  #
  # source://shellany-0.0.1/lib/shellany/sheller.rb:68
  def ok?; end

  # Returns true if the command has already been run, false otherwise.
  #
  # @return [Boolean] whether or not the command has already been run
  #
  # source://shellany-0.0.1/lib/shellany/sheller.rb:60
  def ran?; end

  # Runs the command.
  #
  # @return [Boolean] whether or not the command succeeded.
  #
  # source://shellany-0.0.1/lib/shellany/sheller.rb:44
  def run; end

  # Returns the value of attribute status.
  #
  # source://shellany-0.0.1/lib/shellany/sheller.rb:8
  def status; end

  # Returns the command's error output.
  #
  # @return [String] the command output
  #
  # source://shellany-0.0.1/lib/shellany/sheller.rb:88
  def stderr; end

  # Returns the command's output.
  #
  # @return [String] the command output
  #
  # source://shellany-0.0.1/lib/shellany/sheller.rb:78
  def stdout; end

  class << self
    # Only needed on JRUBY, because MRI properly detects ';' and metachars
    #
    # source://shellany-0.0.1/lib/shellany/sheller.rb:128
    def _shellize_if_needed(args); end

    # source://shellany-0.0.1/lib/shellany/sheller.rb:110
    def _system_with_capture(*args); end

    # source://shellany-0.0.1/lib/shellany/sheller.rb:103
    def _system_with_no_capture(*args); end

    # Shortcut for new(command).run
    #
    # source://shellany-0.0.1/lib/shellany/sheller.rb:24
    def run(*args); end

    # Shortcut for new(command).run.stderr
    #
    # source://shellany-0.0.1/lib/shellany/sheller.rb:36
    def stderr(*args); end

    # Shortcut for new(command).run.stdout
    #
    # source://shellany-0.0.1/lib/shellany/sheller.rb:30
    def stdout(*args); end

    # No output capturing
    #
    # NOTE: `$stdout.puts system('cls')` on Windows won't work like
    # it does for on systems with ansi terminals, so we need to be
    # able to call Kernel.system directly.
    #
    # source://shellany-0.0.1/lib/shellany/sheller.rb:99
    def system(*args); end
  end
end