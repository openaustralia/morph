source 'https://rubygems.org'

ruby '2.3.1'

gem 'dotenv-rails'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.7.1'

# Use sqlite3 as the database for Active Record
# This is a patched version of the gem at https://github.com/openaustralia/sqlite3-ruby/tree/openaustralia-sqlite3
# When/if PR https://github.com/sparklemotion/sqlite3-ruby/pull/123 gets merged and new version of gem gets released
# switch back over to the normal sqlite3 gem
gem 'openaustralia-sqlite3', require: 'sqlite3'
gem 'mysql2'

gem 'haml-rails'
gem 'bootstrap-sass'
gem 'font-awesome-rails'
gem 'bootstrap-select-rails'
gem 'devise'
gem 'omniauth-github'
gem 'friendly_id'
gem 'octokit', '~> 4.0'
gem 'simple_form'
gem 'cocoon'
gem 'grit'
gem 'docker-api', require: 'docker'
gem 'sidekiq'
gem 'sidekiq-limit_fetch'
gem 'redis'
gem 'foreman'
gem 'faraday'
# gem 'jquery-turbolinks'
gem 'archive-tar-minitar'

# We're currently only supporting the plain text, markdown and textile
# markups for the README. If we want more then we need to install some
# more dependencies. See https://github.com/github/markup
gem 'github-markup', require: 'github/markup'
gem 'redcarpet'
gem 'RedCloth'
gem 'rest-client'

# For sidekiq ui
gem 'sinatra', '>= 1.3.0', require: nil
gem 'rails_autolink'
gem 'zeroclipboard-rails'
gem 'newrelic_rpm'
gem 'sitemap_generator'
gem 'kaminari'
gem 'kaminari-bootstrap', '~> 3.0.1'
gem 'rails-timeago', '~> 2.0'
gem 'meta-tags'
# Rails 4 compatibility hasn't been "properly" released yet.
gem 'activeadmin', '~> 1.0.0.pre4'
gem 'faye'
gem 'puma'
# TODO: sync has been renamed to render_sync.
# However version 0.5.0 of render_sync seems to have a problem with the
# renaming of the RefetchesController. So leaving for the time being
gem 'sync'
gem 'multiblock'
gem 'honeybadger'
gem 'cancan'
gem 'backstretch-rails'
gem 'searchkick'
gem 'elasticsearch', '~> 1' # Match version of elasticsearch on the server
gem 'stripe'
gem 'haml-coderay'
gem 'd3-rails'
gem 'validate_url'
gem 'ruby-progressbar'

group :production do
  gem 'dalli'
end

group :development do
  gem 'capistrano-rails'
  gem 'capistrano-rvm'
  gem 'guard'
  gem 'guard-livereload', require: false
  gem 'rack-livereload'
  gem 'guard-rspec', require: false
  gem 'growl'
  # gem "bullet"
  gem 'rack-mini-profiler'
  # gem "flamegraph"

  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'pry-rails'
  gem 'memory_profiler'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'pry-remote'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
end

group :test do
  gem 'capybara'
  gem 'simplecov', require: false
  gem 'factory_girl_rails', '~> 4.0'
  gem 'database_cleaner'
  gem 'vcr'
  gem 'webmock'
  gem 'nokogiri'
  gem 'rspec-activemodel-mocks'
  gem 'codeclimate-test-reporter', require: nil
end

# For our javascript runtime on production we don't want to use therubyracer because it uses too
# much memory. We're assuming Node.js is installed

# Use SCSS for stylesheets
gem 'sass-rails'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails'

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# Disabling so we can browser traces on newrelic
# gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.1.2'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]
