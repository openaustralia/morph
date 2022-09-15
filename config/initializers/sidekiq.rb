# At Rails startup ensure that the sidekiq limit is in synch with the site
# setting
if SiteSetting.table_exists?
  SiteSetting.update_maximum_concurrent_scrapers!
end
