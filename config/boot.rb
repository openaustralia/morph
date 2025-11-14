ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# TODO: Remove the following rails 6.0,6.1 fix when upgrading to Rails 7.0+ (LoggerThreadSafeLevel removed)
require 'logger'

require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
