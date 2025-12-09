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
      "comments/:id" => -> { "comments/#{Comment.last.id}" },
      "users/:id" => -> { "users/#{User.last.id}" },
      "page/:page" => -> { "page/1" }
    }
  end

  let(:legitimate_morph_io_paths) do
    [
      # '/',           # branding in footer
      # '/about',      # mentions in content
      # etc
    ]
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

    routes.each do |route|
      path = route.path.spec.to_s.sub("(.:format)", "")

      # Handle params
      param_substitutions.each do |pattern, value|
        path.gsub!(pattern, value.call.to_s) if path.include?(pattern)
      end

      if path.include?(":")
        puts "Skipping path with unknown params: #{path}"
        next
      end
      next if legitimate_morph_io_paths.include?(path)

      get path
      next unless response.successful?

      violations << path if response.body.include?("morph.io")
    end

    expect(violations).to be_empty,
                          "Found 'morph.io' in responses for:\n#{violations.join("\n")}"
  end
end
