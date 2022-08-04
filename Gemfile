# frozen_string_literal: true

source "https://rubygems.org"

ruby "2.7.6"

gem "dotenv-rails"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "5.2.8.1"

gem "mysql2"
gem "sqlite3"

gem "bootstrap-sass"
gem "bootstrap-select-rails"
gem "cocoon"
gem "devise"
gem "docker-api", require: "docker"

# We're using Faraday directly in one place (to workaround an octokit problem) and that
# depends on version 2.
# For some reason elasticsearch 7.4.0 uses faraday 2, while later 7.x uses faraday 1.
gem "faraday", "~> 2"
gem "faraday-retry"

gem "font-awesome-rails"
# Use same version deployed to server because provisioning/roles/morph-app/tasks/main.yml:80
gem "foreman", "0.63.0"
gem "friendly_id"

# For accessing git from ruby
# See https://github.com/mojombo/grit: "Grit is no longer maintained. Check out rugged."
# TODO: Migrate to rugged or whatever best library is
gem "grit"
gem "rugged"

gem "haml-rails"
gem "octokit", "~> 4.0"
# Because we need the fix
# https://github.com/omniauth/omniauth-github/pull/84/commits/f367321bcf14a57cc9d501375ffebaba8062f449
gem "omniauth-github", "~> 1.4.0"

# We're still on redis 3.x in production so we can't yet upgrade sidekiq to version 6
# TODO: Upgrade sidekiq as soon as we can
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
gem "cancancan"
gem "d3-rails", "~> 3.5"
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

# For the administration interface
gem "activeadmin"

gem "faye"
gem "puma"
gem "ruby-progressbar"
# Using a fork here to include a fix caused by the renaming of the gem to render_sync
# TODO: Move away from this unsupported gem
gem "render_sync", git: "https://github.com/openaustralia/render_sync.git"

# For searchkick 5 we need to install the elasticsearch gem ourselves
# We're using elasticsearch 7 in production so sticking with the same version for the client
gem "elasticsearch", "~> 7"
gem "searchkick", "~> 5"

gem "stripe"
gem "validate_url"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# For type checking
gem "sorbet-static-and-runtime"

group :production do
  gem "dalli"
end

group :development do
  # To help with sorbet type checking
  gem "tapioca", require: false

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
