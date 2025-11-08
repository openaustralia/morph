# frozen_string_literal: true
require_relative "production"

# Staging-specific overrides
Rails.application.configure do
  config.action_mailer.default_url_options = { :host => ENV.fetch("STAGING_HOSTNAME"), protocol: "https" }
end

# So that the same host setting is available outside the mailer
Morph::Application.default_url_options = Morph::Application.config.action_mailer.default_url_options
