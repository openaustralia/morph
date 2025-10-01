Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379') }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379') }
end

# At Rails startup ensure that the sidekiq limit is in synch with the site
# setting  - but only if database exists!
begin
  if SiteSetting.table_exists?
    SiteSetting.update_maximum_concurrent_scrapers!
  end
rescue ActiveRecord::NoDatabaseError, Mysql2::Error::ConnectionError => e
  # Database doesn't exist yet - skip this initialization
  Rails.logger.info "Skipping Sidekiq initialization: #{e}"
end
