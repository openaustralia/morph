ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# Still needed on Rails 6.1: concurrent-ruby >= 1.3.5 stopped requiring
# logger, and ActiveSupport below 7.1 relies on it being loaded.
# Remove when upgrading to Rails 7.1+.
require 'logger'

require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
