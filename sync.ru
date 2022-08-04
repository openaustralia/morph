# typed: false
# frozen_string_literal: true

# Run with: rackup sync.ru -E production
require "bundler/setup"
require "yaml"
require "faye"
require "render_sync"

Faye::WebSocket.load_adapter "puma"

RenderSync.load_config(
  File.expand_path("config/sync.yml", __dir__),
  ENV.fetch("RACK_ENV", nil) || "development"
)

run RenderSync.pubsub_app
