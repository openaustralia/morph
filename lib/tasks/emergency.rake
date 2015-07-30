namespace :app do
  namespace :emergency do
    desc "Reset all user github access tokens (Needed after heartbleed)"
    task :reset_github_access_tokens => :environment do
      User.all.each do |user|
        puts user.nickname
        user.reset_authorization!
      end
    end

    desc 'Update counter caches in case they get out of sync'
    task :update_counter_caches => :environment do
      Run.find_each do |run|
        Run.reset_counters(run.id, :connection_logs)
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

    # TODO: Run this and then remove it
    desc "Create default watches for all users with no current watches"
    task create_all_default_watches: :environment do
      User.where.not(id: Alert.pluck(:user_id)) do |user|
        puts "Creating default watches for #{user.nickname}"
        user.watch_all_owners
      end
    end
  end
end
