# At Rails startup ensure that the sidekiq limit is in synch with the site
# setting
SiteSetting.update_sidekiq_maximum_concurrent_scrapers!
