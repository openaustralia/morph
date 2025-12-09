# typed: false
# frozen_string_literal: true

require "spec_helper"

describe "Hardcoded domain references", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user, admin: true) }

  let(:param_substitutions) do
    {
      "api_queries/:id" => -> { "api_queries/#{ApiQuery.last.id}" },
      "owners/:id" => -> { "owners/#{Owner.last.id}" },
      "runs/:id" => -> { "runs/#{Run.last.id}" },
      "users/:id" => -> { "users/#{User.last.id}" },
      "page/:page" => -> { "page/1" },
      "/:id" => -> { "/#{Scraper.last.full_name}" },
      "/*id" => -> { "/#{Scraper.last.full_name}" }
    }
  end

  let(:legitimate_morph_io_paths) do
    [
      "/discourse/sso", # Special case for Discourse SSO
      # '/',           # branding in footer
      # '/about',      # mentions in content
      # etc
    ]
  end

  before(:all) do
    unless Dir.glob("public/assets/.sprockets-manifest-*.json").any?
      puts "Pre-compiling assets..."
      system("RAILS_ENV=test bundle exec rake assets:precompile")
      @pre_compiled_assets = true
    end
  end

  after(:all) do
    if @pre_compiled_assets
      puts "Cleaning up assets..."
      system("RAILS_ENV=test bundle exec rake assets:clobber")
    end
  end

  before do
    # Create examples for every table
    FactoryBot.lint traits: true
    sign_in user
  end

  it "uses hostname helper instead of hardcoded morph.io" do
    routes = Rails.application.routes.routes
                  .select { |r| r.verb =~ /GET/ }
                  .reject { |r| r.path.spec.to_s.start_with?("/admin/jobs") } # sidekiq
                  .reject { |r| r.path.spec.to_s.start_with?("/rails/") } # rails internals

    violations = []

    puts "DEBUG param_substitutions", param_substitutions.to_yaml

    routes.each do |route|
      path = route.path.spec.to_s.sub("(.:format)", "")
      puts "Checking route path: #{path}"

      # Handle params
      param_substitutions.each do |pattern, value|
        path.gsub!(pattern, value.call.to_s) if path.include?(pattern)
      end

      if path.include?(":")
        puts "Skipping path with unknown params: #{path}"
        next
      end
      next if legitimate_morph_io_paths.include?(path)

      begin
        get path
      rescue ActionView::Template::Error, ActionController::RoutingError => e
        puts "Skipping #{path} due to: #{e.message.lines.first}"
        next
      end
      next unless response.successful?

      # Remove <style> and <link> tags before checking
      html_without_styles = Nokogiri::HTML(response.body)
      html_without_styles.css("style, link[rel=stylesheet]").remove
      violations << path if html_without_styles.to_html.include?("morph.io")

      # violations << path if response.body.include?("morph.io")
    end

    expect(violations).to be_empty,
                          "Found 'morph.io' in responses for:\n#{violations.join("\n")}"
  end
end
