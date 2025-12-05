# frozen_string_literal: true
require_relative "production"

# Staging-specific overrides
Rails.application.configure do
  host = ENV.fetch("SERVER_NAME", 'morph-staging.example.com')
  config.action_mailer.default_url_options = { :host => host, protocol: "https" }
  # FIXME: Change to an oaf test server when we have one
  config.action_mailer.smtp_settings[:address] = ENV.fetch("CUTTLEFISH_SERVER", "plannies-mate.thesite.info")
end

# So that the same host setting is available outside the mailer
Morph::Application.default_url_options = Morph::Application.config.action_mailer.default_url_options
