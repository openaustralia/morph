# Error reporting to Sentry (#1474). Runs alongside Honeybadger while we
# verify it. Without SENTRY_DSN set the SDK initialises but sends nothing,
# so development and test stay quiet by default.
Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.release = APP_VERSION.strip
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
end
