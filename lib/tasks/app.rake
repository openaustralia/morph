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
    total = Scraper.all.count
    i = 1
    Scraper.all.each do |s|
      puts "#{i}/#{total}"
      s.synchronise_repo
      i += 1
    end
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

  # This task should be run from a cron job every 5-10 minutes or so. This is workaround
  # for the fact that to-date we can't completely cleanly clean-up after ourselves properly
  # In an ideal world our container runner would always consistently handle the container
  # cleanup. This doesn't always work. So, that's why we have this workaround.
  #
  # To avoid cleaning up before the container runner has a chance to clean up we only
  # clean up containers that have been stopped for more than 5 minutes.
  desc "Remove stopped containers"
  task :remove_stopped_containers => :environment do
    containers = Docker::Container.all(:all => true)
    containers = containers.select do |c|
      running = c.json["State"]["Running"]
      # Time ago in seconds that this finished
      finished_ago = Time.now - Time::iso8601(c.json["State"]["FinishedAt"])
      # Only show containers that have been stopped for more than 5 minutes
      !running && finished_ago > 5 * 60
    end
    containers.each do |c|
      id = c.id[0..11]
      name = c.info["Names"].first
      finished_ago = Time.now - Time::iso8601(c.json["State"]["FinishedAt"])
      puts "Removing container id: #{id}, name: #{name}, finished: #{finished_ago} seconds ago"
      c.delete
    end
  end

  def confirm(message)
    STDOUT.puts "#{message} (y/n)"
    STDIN.gets.strip == "y"
  end
end
