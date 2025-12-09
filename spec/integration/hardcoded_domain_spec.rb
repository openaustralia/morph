# typed: false
# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/BeforeAfterAll, RSpec/InstanceVariable
describe "Hardcoded domain references", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:active_scraper) do
    Scraper.includes(:owner)
              .find_by("name LIKE 'Active_scraper%'")
  end

  let(:user) do
    # puts "DEBUG Scraper found: #{active_scraper.inspect}"
    # puts "DEBUG Scraper owner found: #{active_scraper.owner.inspect}"
    active_scraper&.owner ||
      raise("No active scraper found!")
  end

  let (:run) do
    active_scraper.runs.last || raise("No active scraper run found!")
  end

  let(:param_substitutions) do
    {
      "api_queries/:id" => -> { "api_queries/#{ApiQuery.last.id}" },
      "owners/:id" => -> { "owners/#{user.id}" },
      "runs/:id" => -> { "runs/#{run.id}" },
      "users/:id" => -> { "users/#{user.id}" },
      "page/:page" => -> { "page/2" },
      "/:id" => -> { "/#{active_scraper.full_name}" },
      "/*id" => -> { "/#{active_scraper.full_name}" }
    }
  end

  let(:legitimate_morph_io_paths) do
    [
      "/", # Lots of blurb about morph.io on the root page
      "/api", # redirects to documentation unless appropriate params are given
      "/discourse/sso", # Special case for Discourse SSO
      "/settings", # redirects to this user's settings page
      "/sign_in", # Dont change the logged in user"
      "/sign_out", # redirects (302) to: /
      "/pricing", # redirects (301) to: /supporters/new
      "/supporters",
      "/supporters/new",
      "/users/auth/github",
      "/users/auth/github/callback",
      "/admin/comments/:id", # No active admin comments!
      "/admin/owners", # FIXME: Nil location provided. Can't build URI
      "/admin/owners/:id/edit", # FIXME: undefined method `inputs' for #<ActiveAdmin::ResourceDSL:0x000060e57f6c4d80>
      "/sync/refetch", # FIXME: Html response status 400 (params needed?)
      "/*id/data", # FIXME: Html response status 401 (params and an sqlite db needed?)
      "/scrapers/github_form", # FIXME: Couldn't find Owner without an ID (id required?)
      "/*id/settings", # FIXME: later - some wierd permission error that doesnt happen in practice (ActiveRecord::RecordNotFound)
    ]
  end

  let(:legit_references) do
    [
      "morph.io is open source",
      # remove app/views/static/_introducing.md
      /Unlock real data from websites like.*share morph.io with you/,
      # remove app/views/static/_signed_out_index.html.haml
      "https://morph.io/rezzo",
      "https://morph.io/hailspuds",
      "I love morph.io because it ",
      "it’s time to get acquainted with morph.io",
      "This week at morph.io",
      "https://morph.io/soit-sk/",
      "dev.morph.io",
      "the morph.io command line client"
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
    admin = User.find_by(admin: true)
    sign_in admin
  end

  it "uses hostname helper instead of hardcoded morph.io" do
    routes = Rails.application.routes.routes
                  .select { |r| r.verb =~ /GET/ }
                  .reject { |r| r.path.spec.to_s.start_with?("/admin/jobs") } # sidekiq
                  .reject { |r| r.path.spec.to_s.start_with?("/rails/") } # rails internals

    violations = {}

    routes.each do |route|
      full_path = route.path.spec.to_s
      path = full_path.sub("(.:format)", "")
      next if legitimate_morph_io_paths.include?(path) || path.start_with?("/documentation")

      param_substitutions.each do |pattern, value|
        path.gsub!(pattern, value.call.to_s) if path.include?(pattern)
      end
      if path.include?(":")
        puts "Skipping path with unknown params: #{full_path} as: #{path}"
        next
      end

      puts "Checking route path: #{full_path} as: #{path}"
      begin
        get path
      rescue ActionView::Template::Error, ActionController::RoutingError, ActiveRecord::RecordNotFound => e
        violations[path] ||= ["Failed to get #{full_path}: #{e.message.lines.first}"]
        next
      end
      unless response.successful?
        if response.status.in?([301, 302])
          location = response.headers["Location"] || "unknown"
          violations[path] ||= ["Failed to get #{full_path}: redirects (#{response.status}) to: #{location}"]
        else
          violations[path] ||= ["Failed to get #{full_path}: Html response status #{response.status}"]
        end
        next
      end

      html = response.body
      legit_references.each do |legit_reference|
        html.gsub!(legit_reference, "")
      end

      next unless html.include?("morph.io")

      # Find context around each occurrence
      matches = []
      html.scan(/.{0,80}morph\.io.{0,80}/m) do |match|
        matches << match.gsub(/\s+/, " ").strip
      end

      violations[path] = matches if matches.any?
    end

    pretty_violations = violations.map { |path, contexts| "#{path}: #{contexts.join(', ')}" }
    expect(violations).to be_empty,
                          "Failures:\n#{pretty_violations.join("\n\n")}"
  end
end
# rubocop:enable RSpec/BeforeAfterAll, RSpec/InstanceVariable
