# frozen_string_literal: true

# Run with: rackup sync.ru -E production
require "bundler/setup"
require "yaml"
require "faye"
require "sync"

Faye::WebSocket.load_adapter "puma"

Sync.load_config(
  File.expand_path("config/sync.yml", __dir__),
  ENV["RACK_ENV"] || "development"
)

run Sync.pubsub_app
