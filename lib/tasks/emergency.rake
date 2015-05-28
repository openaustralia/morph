namespace :app do
  namespace :emergency do
    # This is a temporary workaround for an occasional bug that hits where containers are dissapearing
    # without an exception being thrown or anything like that. So, what we end up with is a running scraper,
    # an associated background job that finished without errors, and no container for that run.
    desc "If there are scrapers that think they're running but there is no container remove the running run"
    task :delete_broken_runs => :environment do
      Run.where("finished_at IS NULL").each do |run|
        run_name = "#{run.id}"
        run_name += " (#{run.scraper.full_name})" if run.scraper
        if run.container_for_run_exists?
          # TODO could potentially check if container is running or stopped and
          # then if it's stopped delete the container (this is assuming that
          # there still is a running background job that will kick in again)
          puts "Container for run #{run_name} exists"
        else
          puts "Container for run #{run_name} doesn't exist. Therefore deleting run"
          # Using destroy to ensure that callbacks are called (mainly for caching)
          run.destroy
        end
      end
    end

    desc "Reset all user github access tokens (Needed after heartbleed)"
    task :reset_github_access_tokens => :environment do
      User.all.each do |user|
        puts user.nickname
        user.reset_authorization!
      end
    end

    desc "Get meta info for all domains in the connection logs"
    task :get_all_meta_info_for_connection_logs => :environment do
      domains = ConnectionLog.group(:host).pluck(:host)
      total = domains.count
      domains.each_with_index do |domain, index|
        if Domain.where(name: domain).exists?
          puts "Skipping #{index + 1}/#{total} #{domain}"
        else
          puts "Queueing #{index + 1}/#{total} #{domain}"
          d = Domain.create!(name: domain)
          UpdateDomainWorker.perform_async(d.id)
        end
      end
    end
  end
end
