# frozen_string_literal: true

# Pick up ENV from .env file

require "dotenv"
Dotenv.load

# Load DSL and Setup Up Stages
require "capistrano/setup"

# Includes default deployment tasks
require "capistrano/deploy"

require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# Includes tasks from other gems included in your Gemfile
#
# For documentation on these, see for example:
#
#   https://github.com/capistrano/rvm
#   https://github.com/capistrano/rbenv
#   https://github.com/capistrano/chruby
#   https://github.com/capistrano/bundler
#   https://github.com/capistrano/rails/tree/master/assets
#   https://github.com/capistrano/rails/tree/master/migrations
#
# capistrano-rvm and capistrano-rbenv each hook every stage once loaded, so load
# only the one the stage in use needs. The rehearsal stage, and a later production
# stage, use rbenv. staging and local keep rvm until the old provisioning is retired.
RBENV_STAGES = %w[rehearsal production].freeze
if ARGV.intersect?(RBENV_STAGES)
  require "capistrano/rbenv"
else
  require "capistrano/rvm"
end
# require 'capistrano/chruby'
require "capistrano/bundler"
require "capistrano/rails/assets"
require "capistrano/rails/migrations"
require "capistrano/tagging3"

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob("lib/capistrano/tasks/*.cap").each { |r| import r }
