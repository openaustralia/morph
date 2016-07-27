namespace :app do
  desc 'Stop long running scraper containers (should be run from cron job)'
  task stop_long_running_scrapers: :environment do
    # TODO Move this a configuration. Also, it's referenced in the documentation
    # So, the two should really be automatically in sync
    max_duration = 1.day

    # Let's start by just showing running containers
    containers = Morph::DockerUtils.running_containers
    # Select containers that are scraper runs
    containers = containers.select { |c| Morph::Runner.run_id_for_container(c) }

    containers.each do |container|
      start_time = Time.parse(container.json['State']['StartedAt'])
      if start_time < max_duration.ago
        run = Morph::Runner.run_for_container(container)
        runner = Morph::Runner.new(run)
        puts "Stopping #{run.full_name} because its container has been running longer than #{max_duration.inspect}"
        runner.log(:internalerr, "Stopping scraper because it has run longer than #{max_duration.inspect}\n")
        container.kill
      end
    end
  end

  desc 'Run scrapers that need to run once per day' \
    ' (this task should be called from a cron job)'
  task auto_run_scrapers: :environment do
    # All the scrapers that need running in a random order
    scraper_ids = Scraper.where(auto_run: true).map(&:id).shuffle
    interval = 24.hours / scraper_ids.count
    time = 0
    scraper_ids.each do |scraper_id|
      ScraperAutoRunWorker.perform_in(time, scraper_id)
      time += interval
    end
    puts "Queued #{scraper_ids.count} scrapers to run over the next 24 hours"
  end

  desc 'Send out alerts for all users (Run once per day with a cron job)'
  task send_alerts: :environment do
    User.process_alerts
  end

  desc 'Refresh info for all users from github'
  task refresh_all_users: :environment do
    User.all.each do |u|
      RefreshUserInfoFromGithubWorker.perform_async(u.id)
    end
  puts 'Put jobs on to the background queue to refresh all user info from github'
  end

  desc 'Refresh info for all organizations from github'
  task refresh_all_organizations: :environment do
    Organization.all.each do |org|
      RefreshOrganizationInfoFromGithubWorker.perform_async(org.id)
    end
  puts 'Put jobs on to the background queue to refresh all organization info from github'
  end

  desc 'Build docker image (Needs to be done once before any scrapers are run)'
  task update_docker_image: :environment do
    Morph::DockerRunner.update_docker_image!
  end

  desc 'Synchronise all repositories'
  task synchronise_repos: :environment do
    Scraper.all.each do |s|
      SynchroniseRepoWorker.perform_async(s.id)
    end
    puts 'Put jobs on to the background queue to synchronise all repositories'
  end

  desc 'Promote user to admin'
  task promote_to_admin: :environment do
    puts 'Which github nickname do you want to promote to admin?'
    nickname = $stdin.gets.chomp
    user = User.find_by_nickname(nickname)
    if user
      user.admin = true
      user.save!
      puts 'Done!'
    else
      puts "Couldn't find user with nickname '#{nickname}'"
      exit 1
    end
  end

  desc 'Backup databases to db/backups'
  task backup: :environment do
    Morph::Backup.backup
  end

  desc 'Restore databases from db/backups'
  task restore: :environment do
    if confirm 'Are you sure?' \
      ' This will overwrite the databases and Redis needs to be shutdown.'
      Morph::Backup.restore
    end
  end

  desc "Tidies up Docker containers and images (should be run from a cronjob)"
  task :docker_tidy_up do
    task("app:docker:remove_old_unused_images").invoke
    task("app:docker:delete_dead_containers").invoke
    task("app:docker:delete_old_stopped_containers").invoke
  end

  # FIXME: This is a workaround for the problem in https://github.com/openaustralia/morph/issues/910
  desc "Creates missing run workers for scrapers that are running"
  task create_missing_run_workers: :environment do
    # Get runs that have a background worker
    workers = Sidekiq::Workers.new
    active_runs = workers.collect do |process_id, thread_id, work|
      work["payload"]["args"].first if work["queue"] == "scraper"
    end

    # Recreate missing background processes for running scrapers
    Scraper.running.each do |scraper|
      run_id = scraper.last_run.id

      if !active_runs.include?(run_id)
        puts "Creating run worker for run ID: #{run_id}"
        RunWorker.perform_async(run_id)
      end
    end
  end

  desc "Remove log lines for old runs (not the latest ones)"
  task clean_up_old_log_lines: :environment do
    Scraper.all.each do |scraper|
      puts "Removing old logs for #{scraper.full_name}..."
      runs = scraper.runs.order(queued_at: :desc)
      # Remove the most recently run from the list
      runs = runs[1..-1]
      # Now remove the logs connected to those runs
      LogLine.delete_all(run: runs)
    end
  end

  def confirm(message)
    STDOUT.puts "#{message} (y/n)"
    STDIN.gets.strip == 'y'
  end
end
