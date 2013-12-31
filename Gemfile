source 'https://rubygems.org'

gem 'dotenv-rails', :groups => [:development, :test]

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.0.2'

# Use sqlite3 as the database for Active Record
gem 'sqlite3'

gem "haml-rails"
gem "twitter-bootstrap-rails"
gem "devise"
gem "omniauth-github"
gem 'friendly_id'
gem "octokit"
gem "formtastic-bootstrap"
# This release candidate of formtastic has a fix for:
# undefined method `check_box_checked?' for ActionView::Helpers::InstanceTag:Class
gem "formtastic", "2.3.0.rc2"
gem "grit"
gem 'docker-api', :require => 'docker'
gem 'delayed_job_active_record'
gem "foreman"

group :development do
  gem 'capistrano-rails'
  gem 'capistrano-rvm'
end

group :production do
  # Javascript runtime (required for precompiling assets in production)
  gem 'therubyracer'
end

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

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
