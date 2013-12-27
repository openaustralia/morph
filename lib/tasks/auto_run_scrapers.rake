namespace :app do
  desc "Run scrapers that need to run once per day (this task should be called from a cron job)"
  task :auto_run_scrapers => :environment do
    scrapers = Scraper.where(auto_run: true)
    scrapers.each {|scraper| scraper.delay.go_delayed}
    puts "Queued #{scrapers.count} scrapers to run now"
  end
end
