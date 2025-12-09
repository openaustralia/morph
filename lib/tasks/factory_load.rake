# typed: false
# frozen_string_literal: true

namespace :db do
  namespace :factory do
    desc "Reset database and load spec factory (test) data (both minimal and maximal records)"
    task load: :environment do
      raise "This task can only be run in development environment!" unless Rails.env.development?

      puts "Resetting database..."
      Rake::Task["db:reset"].invoke

      puts "Disabling update of ElasticSearch index..."
      Searchkick.disable_callbacks

      puts "Disabling github validations as we are loading fake scrapers ..."
      Scraper.skip_github_validations = true

      puts "Loading test data..."
      require "factory_bot_rails"
      require_relative "../../spec/support/factory_helpers"
      include FactoryHelpers

      # trigger creation of SiteSetting record
      SiteSetting.maximum_concurrent_scrapers

      # Create all the possible factory examples
      FactoryBot.lint traits: true

      admin = User.find_by admin: true

      puts ""
      puts "Admin user nickname: #{admin.nickname}",
           "              email: #{admin.email}"
      puts ""

      Rake::Task["db:stats"].invoke
    end
  end
end
