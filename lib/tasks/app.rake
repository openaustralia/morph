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

  desc "Backup databases to db/backups"
  task :backup => :environment do
    Morph::Backup.backup
  end

  desc "Restore databases from db/backups"
  task :restore => :environment do
    Morph::Backup.restore if confirm("Are you sure? This will overwrite the databases and Redis needs to be shutdown.")
  end

  def confirm(message)
    STDOUT.puts "#{message} (y/n)"
    STDIN.gets.strip == "y"
  end
end
