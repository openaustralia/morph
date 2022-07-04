# frozen_string_literal: true

source "https://rubygems.org"

ruby "2.4.10"

gem "dotenv-rails"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "4.2.11.1"

gem "sqlite3"
# The very latest mysql2 gem versions only work with rails 5
gem "mysql2", "~> 0.4.10"

gem "bootstrap-sass"
gem "bootstrap-select-rails"
gem "cocoon"
gem "devise"
gem "docker-api", require: "docker"
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
gem "redis"
gem "sidekiq"
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
gem "elasticsearch"
gem "haml-coderay"
gem "honeybadger"
gem "kaminari"
gem "kaminari-bootstrap", "~> 3.0.1"
gem "meta-tags"
gem "multiblock"
gem "rails-timeago", "~> 2.0"
gem "rails_autolink"
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

# nio4r isn't a direct dependency. It's used by puma but we're including
# it here to lock the version to one that works with ruby 2.3
# TODO: Remove this when we can
gem "nio4r", "~> 2.4.0"

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
  gem "rack-mini-profiler"
  # gem "flamegraph"

  gem "better_errors"
  gem "binding_of_caller"
  gem "memory_profiler"
  gem "pry-rails"
  gem "spring"
  gem "spring-commands-rspec"

  gem "rubocop"
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
  gem "factory_girl_rails", "~> 4.0"
  gem "nokogiri"
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
