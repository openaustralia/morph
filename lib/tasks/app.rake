namespace :app do
  desc "Run scrapers that need to run once per day (this task should be called from a cron job)"
  task :auto_run_scrapers => :environment do
    scrapers = Scraper.where(auto_run: true)
    scrapers.each {|scraper| scraper.queue!(true)}
    puts "Queued #{scrapers.count} scrapers to run now"
  end

  desc "Refresh info for all users from github"
  task :refresh_all_users => :environment do
    User.all.each {|user| user.refresh_info_from_github!}
  end

  desc "Build docker image (Needs to be done once before any scrapers are run)"
  task :update_docker_image => :environment do
    Scraper.update_docker_image!
  end
end
