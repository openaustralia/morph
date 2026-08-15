# frozen_string_literal: true

# IMPORTANT - ALWAYS Regenerate Sorbet RBI files when you update gem versions
# bundle exec tapioca gem

source "https://rubygems.org"

ruby "2.7.6"

gem "dotenv-rails"

gem "rails", "6.0.6.1"

gem "mysql2"
gem "sqlite3"

gem "bootstrap-sass"
# Used to put images inside pulldowns
gem "bootstrap-select-rails"
gem "cocoon"
gem "devise"
gem "docker-api", require: "docker"

# We're using Faraday directly in one place (to workaround an octokit problem) and that
# depends on version 2.
# For some reason elasticsearch 7.4.0 uses faraday 2, while later 7.x uses faraday 1.
gem "faraday", "~> 2" # CVE-2026-25765, CVE-2026-33637, CVE-2026-54297 need >= 2.14.1, which needs Ruby >= 3.0; blocked on Ruby upgrade
gem "faraday-retry"

gem "font-awesome-rails"
# Use same version as ruby-foreman package as Production uses system foreman
gem "foreman", "0.63.0"
gem "friendly_id"

# For accessing git from ruby
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
gem "RedCloth", ">= 4.3.3" # fix CVE-2023-31606 (ReDoS)
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
gem "sinatra", ">= 2.2.3", require: nil # fix CVE-2022-45442; CVE-2024-21510 and CVE-2025-61921 need sinatra 4.x, tracked separately
gem "sitemap_generator"
gem "zeroclipboard-rails"

# For the administration interface
gem "activeadmin"

gem "faye"
gem "puma", ">= 5.6.9" # fix CVE-2023-40175, CVE-2024-21647, CVE-2024-45614; CVE-2026-47736/47737 need puma 7.2+/8.0+, tracked separately
gem "ruby-progressbar"
# Using a fork here to include a fix caused by the renaming of the gem to render_sync
# TODO: Move away from this unsupported gem
gem "render_sync", git: "https://github.com/openaustralia/render_sync.git"

# For searchkick 5 we need to install the elasticsearch gem ourselves
# We're using elasticsearch 7 in production so sticking with the same version for the client
gem "elasticsearch", "~> 7.17"
gem "searchkick", "~> 5"

gem "stripe"
gem "validate_url"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", "~> 1.4", require: false

# For type checking
gem "sorbet-static-and-runtime"

# Psych 4 introduced breaking changes by changing default to safe mode.
#   Rails 6.1 has fix: https://github.com/rails/rails/commit/255b5ff9af57f9b54dee7ec884b12a1ad16f0321
# TODO: Change to ">= 5.2.4" when we upgrade to Rails 6.1 to pick up security fixes
gem "psych", ">= 3.3.4", "< 4"

# For making JSON Web Tokens used by Github API
gem "jwt", ">= 2.10.3" # fix CVE-2026-45363

group :production do
  gem "dalli", ">= 3.2.3" # fix CVE-2022-4064
end

group :development do
  # To help with sorbet type checking
  gem "rspec-sorbet"
  gem "spoom"
  gem "tapioca", require: false

  gem "haml-lint"

  gem "bcrypt_pbkdf", "~> 1.1"
  gem "capistrano-rails", require: false
  gem "capistrano-rvm", require: false
  gem "capistrano-tagging3", require: false
  gem "ed25519", "~> 1.3"

  gem "growl"
  gem "guard"
  gem "guard-livereload", require: false
  gem "guard-rspec", require: false
  # gem "bullet"
  gem "rack-livereload"
  gem "rack-mini-profiler"
  # gem "flamegraph"

  gem "annotaterb", "~> 4.15.0" # 4.16+ requires ruby 3.0
  gem "better_errors"
  gem "binding_of_caller"
  gem "memory_profiler"
  gem "pry-rails"
  gem "spring", "~> 4.0"
  gem "spring-commands-rspec"

  gem "bundle-audit", require: false
  gem "rubocop"
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-sorbet", require: false
  gem "ruby_audit", require: false

  gem "mailcatcher", require: false
end

group :development, :test do
  gem "pry-remote"
  gem "pry-rescue"
  gem "pry-stack_explorer"
  gem "rspec-rails"
end

group :test do
  gem "capybara"
  gem "database_cleaner"
  gem "factory_bot_rails"
  gem "nokogiri", "~> 1.15.7" # last version supporting Ruby 2.7; GHSAs need >= 1.16 (Ruby >= 3.0), blocked on Ruby upgrade
  gem "rails-controller-testing"
  gem "rspec-activemodel-mocks"
  gem "simplecov", require: false
  gem "simplecov-console", require: false
  gem "simplecov-teamcity-summary", require: false
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
# Hold back jquery-ui-rails. We get Sprockets::FileNotFound with a newer version
gem "jquery-ui-rails", "~> 5"

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# Disabling so we can browser traces on newrelic
# gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder"

# Force loading the latest security patch
gem "sprockets", "~> 4.0"

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem "sdoc", require: false
end

# Default gems that need explicit inclusion for deployment
gem "date"

# --- Transitive dependency security floors ---
# Not direct dependencies, but bundler-audit flags them; pinning floors
# here prevents a future lockfile regen from resolving back down.
gem "rack", ">= 2.2.23", "< 3" # fix 10 CVEs incl. GHSA-8vqr, GHSA-h2jq (High); staying on rack 2.x to match actionpack/sidekiq/sinatra's existing ~> 2.0 constraints
gem "loofah", ">= 2.25.2" # fix GHSA-9wjq-cp2p-hrgf (via rails-html-sanitizer, actiontext)
gem "rails-html-sanitizer", ">= 1.7.1" # fix GHSA-cj75-f6xr-r4g7 (via actionview)
gem "crass", ">= 1.0.7" # fix 4 GHSAs, no CVEs assigned (via loofah)
gem "addressable", ">= 2.9.0" # fix CVE-2026-35611 (via capybara, webmock, octokit chain)
gem "concurrent-ruby", ">= 1.3.7" # fix CVE-2026-54904/54905/54906 (via activesupport, sprockets)
gem "bcrypt", ">= 3.1.22" # fix CVE-2026-33306 (via devise)
gem "msgpack", ">= 1.8.2" # fix CVE-2026-54522 (via bootsnap)
gem "webrick", ">= 1.8.2" # fix CVE-2025-6442 (via yard, mailcatcher)
gem "websocket-driver", ">= 0.8.2" # fix CVE-2026-54463/54464/54465/61666 (via faye, actioncable)
gem "oauth2", ">= 2.0.22" # fix GHSA-pp92-crg2-gfv9 (via omniauth-oauth2, octokit chain)
gem "rexml", ">= 3.3.9" # fix CVE-2024-49761 and others (via rubocop, crack)
gem "rdoc", ">= 6.3.4.1" # fix CVE-2024-27281 (RCE, via sdoc)
gem "yard", ">= 0.9.44" # fix CVE-2026-41493, CVE-2026-49342 (via tapioca)
gem "net-imap", ">= 0.4.24" # fix CVE-2026-42245/42256/42257/42258 (via mail); CVE-2026-47240/47241/47242 need 0.5.15+, tracked separately
gem "omniauth", ">= 1.9.2" # fix CVE-2020-36599 (via omniauth-github); CVE-2015-9284 CSRF fix needs omniauth 2.0, blocked by omniauth-github's ~> 1.5.0 pin, tracked separately

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.1.2'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]
