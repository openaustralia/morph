# typed: false
# frozen_string_literal: true

require "simplecov"
require "simplecov_json_formatter"
require "simplecov-console"

dont_run_github = ENV["DONT_RUN_GITHUB_TESTS"] || !File.exist?("config/morph-github-app.private-key.pem") # Morph::GithubAppInstallation::MORPH_GITHUB_APP_PRIVATE_KEY_PATH
dont_run_docker = ENV["DONT_RUN_DOCKER_TESTS"] || !system("docker -v > /dev/null 2>&1") || !system("docker info > /dev/null 2>&1")
run_slow_tests = ENV.fetch("RUN_SLOW_TESTS", nil)

SimpleCov.start "rails" do
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
    [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Console,
      SimpleCov::Formatter::JSONFormatter
    ]
  )
  track_files "**/*.rb"
  # Filter coverage to relevant files when running specific specs
  # Detect if this is a focused/targeted run
  spec_files = ARGV.select { |arg| arg.match(/\A[^*]+_spec\.rb\z/) }
  spec_files += ENV["SPEC"].split(/\s+/) if ENV["SPEC"]
  if spec_files.any?
    require "active_support/inflector"

    # Extract base names from spec files (strip _spec.rb and type suffixes)
    puts "NOTE: Filtering coverage based on #{spec_files.size} spec files:"
    base_names = spec_files.flat_map do |file|
      name = File.basename(file, ".rb")
      base = name.sub(/_spec$/, "").sub(/_(ability|controller|decorator|helper|job|mailer|policy|rake|serializer|service|worker)$/, "")
      list = [base, base.singularize, base.pluralize].uniq
      puts "  #{list.join(', ')}"
      list
    end.uniq

    # Only show coverage for files matching these base names
    add_filter do |src|
      base_names.none? { |name| src.filename.include?(name.to_s) }
    end
  elsif ARGV.none? { |arg| arg.include?("--example") }
    expected_coverage = if run_slow_tests && !(dont_run_docker || dont_run_github)
                          # `make all-tests` coverage when docker is installed and github app private keyfile exists
                          86.32
                        elsif run_slow_tests
                          # `make ci-tests` coverage
                          85.70
                        else
                          # `make quick-tests` coverage
                          78.05
                        end
    SimpleCov.minimum_coverage expected_coverage - 0.01
  end
  add_filter %r{^/spec/}
  add_filter "/vendor/"
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
require "rspec/rails"
require "capybara/rspec"
require "rspec/sorbet"

# Commented out for the benefit of zeus
# require 'rspec/autorun'

# Requires supporting ruby files with custom matchers and macros, etc.
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

VCR.configure do |c|
  c.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  c.hook_into :webmock
  c.ignore_hosts "codeclimate.com"
  c.ignore_request do |_request|
    RSpec.current_example&.metadata&.fetch(:github_integration, false)
  end
end

# We don't want webmock to get involved with the excon library at all
# Otherwise tests that involve streaming output from a docker container
# just buffer. It took way too long to figure out where the problem was!
WebMock::HttpLibAdapters::ExconAdapter.disable!

# See https://github.com/mperham/sidekiq/wiki/Testing for details
require "sidekiq/testing"
Sidekiq::Testing.fake!

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.infer_spec_type_from_file_location!

  config.include FactoryBot::Syntax::Methods
  config.include DockerImageHelper
  config.include RetryHelper

  config.before(:suite) do
    Searchkick.disable_callbacks
    DatabaseCleaner.start
    # Check factories create valid records (then clean them out)
    FactoryBot.lint
  ensure
    DatabaseCleaner.clean
  end

  # For tests marked as :docker tests don't use VCR
  config.around do |ex|
    if ex.metadata.key?(:docker)
      VCR.turned_off do
        WebMock.allow_net_connect!
        ex.run
      end
    else
      ex.run
    end
  end

  config.filter_run_excluding github: true if dont_run_github
  config.filter_run_excluding docker: true if dont_run_docker
  config.filter_run_excluding slow: true unless run_slow_tests

  # Make sure sidekiq jobs don't linger between tests
  config.before do
    Sidekiq::Worker.clear_all
  end

  RSpec::Sorbet.allow_doubles!
end
