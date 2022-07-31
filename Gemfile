# frozen_string_literal: true

source "https://rubygems.org"

ruby "2.5.9"

# we are locking the version because the latest
# version breaks with the old ruby (2.5.9) that we're currently using
# TODO: Remove this restriction as soon as we can
gem "dotenv-rails", "< 2.8.0"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "5.0.7.2"

gem "mysql2"
gem "sqlite3"

gem "bootstrap-sass"
gem "bootstrap-select-rails"
gem "cocoon"
gem "devise"
# Version 2.0.0 of the gem removes Docker::API_VERSION. See https://github.com/upserve/docker-api/commit/f977568213354b4e8c347eeede1346d53aeec723
# We're currently using that in morph
# TODO: Remove use of Docker::API_VERSION so we can upgrade this gem further
gem "docker-api", "< 2.0.0", require: "docker"
gem "faraday"
gem "font-awesome-rails"
# Use same version deployed to server because provisioning/roles/morph-app/tasks/main.yml:80
gem "foreman", "0.63.0"
gem "friendly_id"
gem "grit"
gem "haml-rails"
gem "octokit", "~> 4.0"
# Because we need the fix
# https://github.com/omniauth/omniauth-github/pull/84/commits/f367321bcf14a57cc9d501375ffebaba8062f449
gem "omniauth-github", "~> 1.4.0"
# To avoid deprecation warnings with an old version of sidekiq that we are currently forced
# to use because we're using ruby 2.4
# TODO: Remove this after we upgrade to ruby 2.6.3 or later
gem "redis", "< 4.6.0"
# TODO: Upgrade to sidekiq 6
gem "sidekiq", "~> 5"
gem "sidekiq-limit_fetch"
gem "simple_form"
# gem 'jquery-turbolinks'
gem "archive-tar-minitar"

# We're currently only supporting the plain text, markdown and textile
# markups for the README. If we want more then we need to install some
# more dependencies. See https://github.com/github/markup
gem "github-markup", require: "github/markup"
gem "redcarpet"
gem "RedCloth"
gem "rest-client"

gem "backstretch-rails"
gem "cancan"
gem "d3-rails", "~> 3.5"
# Locking elasticsearch to 7.5.0 as upgrading it seems to break things working
# with the ancient version of elasticsearch (1.x) that we're running currently
# This lock is also stopping us from upgrading faraday which is giving us
# deprecation warnings.
# TODO: Upgrade elasticsearch as soon as we can
gem "elasticsearch", "7.5.0"
gem "haml-coderay"
gem "honeybadger"
gem "kaminari"
gem "kaminari-bootstrap", "~> 3.0.1"
gem "meta-tags"
gem "multiblock"
gem "rails_autolink"
gem "rails-timeago", "~> 2.0"
# For sidekiq ui
gem "sinatra", ">= 1.3.0", require: nil
gem "sitemap_generator"
gem "zeroclipboard-rails"
# Rails 4 compatibility hasn't been "properly" released yet.
gem "activeadmin", "~> 1.0.0.pre4"
gem "faye"
gem "puma"
gem "ruby-progressbar"
# Using a fork here to include a fix caused by the renaming of the gem to render_sync
# TODO: Move away from this unsupported gem
gem "render_sync", git: "https://github.com/openaustralia/render_sync.git"

# We can't use anything later than 1.5.1 if we're on elasticsearch 1.x
# See https://github.com/ankane/searchkick/blob/master/README.md
gem "searchkick", "1.5.1"
gem "stripe"
gem "validate_url"

# Adding psych here to lock its version. psych 4.0 causes us issues with installing gems. Ugh.
# TODO: Remove this as soon as possible
gem "psych", "< 4.0.0"

group :production do
  gem "dalli"
end

group :development do
  gem "capistrano-rails"
  gem "capistrano-rvm"
  gem "growl"
  gem "guard"
  gem "guard-livereload", require: false
  gem "guard-rspec", require: false
  # gem "bullet"
  gem "rack-livereload"
  # 3.0.0 requires at least ruby 2.5
  gem "rack-mini-profiler", "< 3.0.0"
  # gem "flamegraph"

  gem "better_errors"
  gem "binding_of_caller"
  gem "memory_profiler"
  gem "pry-rails"
  gem "spring"
  gem "spring-commands-rspec"

  gem "rubocop"
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
end

group :development, :test do
  gem "pry-remote"
  gem "pry-rescue"
  gem "pry-stack_explorer"
  gem "rspec-rails"
end

group :test do
  gem "capybara"
  gem "codeclimate-test-reporter", require: nil
  gem "database_cleaner"
  gem "factory_bot_rails"
  gem "nokogiri"
  gem "rails-controller-testing"
  gem "rspec-activemodel-mocks"
  gem "simplecov", require: false
  gem "timecop"
  gem "vcr"
  gem "webmock"
end

# For our javascript runtime on production we don't want to use therubyracer because it uses too
# much memory. We're assuming Node.js is installed

# Use SCSS for stylesheets
gem "sass-rails"

# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"

# Use CoffeeScript for .js.coffee assets and views
gem "coffee-rails"

# Use jquery as the JavaScript library
gem "jquery-rails"
# Hold back jquery-ui-rails. We get Sprockets::FileNotFound with newer version
gem "jquery-ui-rails", "~> 5"

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# Disabling so we can browser traces on newrelic
# gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder"

# We're only including sprockets here so we can lock it to an older version
# For upgrading: https://github.com/rails/sprockets/blob/070fc01947c111d35bb4c836e9bb71962a8e0595/UPGRADING.md#manifestjs
# TODO: Upgrade to sprockets version 4 and remove the line below
gem "sprockets", "~> 3"

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem "sdoc", require: false
end

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.1.2'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]
