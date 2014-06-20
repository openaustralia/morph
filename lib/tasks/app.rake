namespace :app do
  desc "Run scrapers that need to run once per day (this task should be called from a cron job)"
  task :auto_run_scrapers => :environment do
    # All the scrapers that need running in a random order
    scraper_ids = Scraper.where(auto_run: true).map{|s| s.id}.shuffle
    interval = 24.hours / scraper_ids.count
    time = 0
    scraper_ids.each do |scraper_id|
      ScraperAutoRunWorker.perform_in(time, scraper_id)
      time += interval
    end
    puts "Queued #{scraper_ids.count} scrapers to run over the next 24 hours"
  end

  desc "Send out alerts for all users (Run once per day with a cron job)"
  task :send_alerts => :environment do
    User.process_alerts
  end

  desc "Refresh info for all users from github"
  task :refresh_all_users => :environment do
    User.all.each {|user| user.refresh_info_from_github!}
  end

  desc "Build docker image (Needs to be done once before any scrapers are run)"
  task :update_docker_image => :environment do
    Scraper.update_docker_image!
  end

  desc "Synchronise all repositories"
  task :synchronise_repos => :environment do
    Scraper.all.each{|s| s.synchronise_repo}
    end

  desc "Promote user to admin"
  task :promote_to_admin => :environment do
    puts "Which github nickname do you want to promote to admin?"
    nickname = $stdin.gets.chomp
    user = User.find_by_nickname(nickname)
    if user
      user.admin = true
      user.save!
      puts "Done!"
    else
      puts "Couldn't find user with nickname '#{nickname}'"
      exit 1
    end
  end

  namespace :backup do
    desc "Backup mysql database to db/backups"
    task :mysql => :environment do
      FileUtils.mkdir_p("db/backups")
      puts "Backing up MySQL..."
      system("mysqldump -u scraping -pscraping scraping_development > db/backups/mysql_backup.sql")
      puts "Compressing MySQL backup..."
      system("bzip2 db/backups/mysql_backup.sql")
    end
  end

  namespace :restore do
    desc "Restore mysql database from db/backups"
    task :mysql => :environment do
      # TODO Confirm that the user really wants to do this
      puts "Uncompressing MySQL backup..."
      system("bunzip2 -k db/backups/mysql_backup.sql.bz2")
      puts "Restoring from MySQL backup..."
      system("mysql -u scraping -pscraping scraping_development < db/backups/mysql_backup.sql")
      FileUtils.rm_f("db/backups/mysql_backup.sql")
    end
  end
end
