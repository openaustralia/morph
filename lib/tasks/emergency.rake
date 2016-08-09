namespace :app do
  namespace :emergency do
    desc 'Show queue / run inconsistencies - does not make any changes'
    task show_queue_run_inconsistencies: :environment do
      RUN_WORKER_CLASS_NAME = 'RunWorker'
      SCRAPER_QUEUE = 'scraper'

      # We just want to highlight the inconsistencies so that a person
      # can intervene and understand what's causing these problems. It would be
      # too crude to try to fix things automagically as we would rather fix
      # or remediate the underlying problem. If we work around things too
      # automatically then we ensure that we never actually fix the problem
      # properly and it will undoubtedly come back in some other way.

      # TODO: Show containers that have a run label but there isn't a job on the
      # queue for that run
      # TODO: Show runs from the database that say they are running (or queued)
      # but there is no job on the queue for that run - have different handling
      # for runs that are started from a scraper and those that are started from
      # morph-cli

      # First find all the runs that are currently in the queue somewhere
      queue = []
      # Runs on the retry queue
      Sidekiq::RetrySet.new.each do |job|
        queue << job.args.first if job.klass == RUN_WORKER_CLASS_NAME
      end
      # Runs on the queue
      Sidekiq::Queue.new(SCRAPER_QUEUE).each do |job|
        queue << job.args.first if job.klass == RUN_WORKER_CLASS_NAME
      end
      # Runs currently being processed on the queue
      Sidekiq::Workers.new.each do |_process_id, _thread_id, work|
        if work['payload']['class'] == RUN_WORKER_CLASS_NAME
          queue << work['payload']['args'].first
        end
      end
      # Remove duplicates just in case a job has moved from one queue to another
      # while we've been doing this
      queue = queue.uniq.sort
      puts 'Current runs ids on the queue:'
      p queue
    end

    desc 'Reset all user github access tokens (Needed after heartbleed)'
    task reset_github_access_tokens: :environment do
      User.all.each do |user|
        puts user.nickname
        user.reset_authorization!
      end
    end

    desc 'Update counter caches in case they get out of sync'
    task update_counter_caches: :environment do
      Run.find_each do |run|
        Run.reset_counters(run.id, :connection_logs)
      end
    end

    desc 'Get meta info for all domains in the connection logs'
    task get_all_meta_info_for_connection_logs: :environment do
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

    desc 'Delete duplicate enqueued Sidekiq scraper jobs. Sidekiq should be stopped for this to be effective'
    task delete_duplicate_scraper_jobs: :environment do
      queue = Sidekiq::Queue['scraper'].to_a
      queue.each do |x|
        if queue.count { |y| x.item['args'].first == y.item['args'].first } > 1
          puts "Deleting duplicate job for run ID: #{x.item['args'].first}..."
          x.delete
        end
      end
    end

    # See https://github.com/openaustralia/morph/issues/1038
    desc 'Removed records from other tables associated with deleted scrapers'
    task fix_referential_integrity: :environment do
      def destroy_by_id(model, ids)
        progressbar = ProgressBar.create(title: model.name.pluralize, total: ids.count, format: '%t: |%B| %E')
        ids.each do |id|
          model.find(id).destroy
          progressbar.increment
        end
      end

      ids = Alert.connection.select_all("SELECT id FROM alerts WHERE watch_type = 'Scraper' AND watch_id NOT IN (SELECT id FROM scrapers)").map { |id| id['id'] }
      destroy_by_id(Alert, ids)

      ids = ApiQuery.connection.select_all('SELECT id FROM api_queries WHERE scraper_id NOT IN (SELECT id FROM scrapers)').map { |id| id['id'] }
      destroy_by_id(ApiQuery, ids)

      ids = Contribution.connection.select_all('SELECT id FROM contributions WHERE scraper_id NOT IN (SELECT id FROM scrapers)').map { |id| id['id'] }
      destroy_by_id(Contribution, ids)

      ids = Run.connection.select_all('SELECT id FROM runs WHERE scraper_id NOT IN (SELECT id FROM scrapers)').map { |id| id['id'] }
      destroy_by_id(Run, ids)

      ids = Variable.connection.select_all('SELECT id FROM variables WHERE scraper_id NOT IN (SELECT id FROM scrapers)').map { |id| id['id'] }
      destroy_by_id(Variable, ids)

      ids = Webhook.connection.select_all('SELECT id FROM webhooks WHERE scraper_id NOT IN (SELECT id FROM scrapers)').map { |id| id['id'] }
      destroy_by_id(Webhook, ids)

      ids = ConnectionLog.connection.select_all('SELECT id FROM connection_logs WHERE run_id NOT IN (SELECT id FROM runs)').map { |id| id['id'] }
      # Only try to delete 1000 at a time
      ids.each_slice(1000) do |slice|
        ConnectionLog.where(id: slice).delete_all
      end

      ids = LogLine.connection.select_all('SELECT id FROM log_lines WHERE run_id NOT IN (SELECT id FROM runs)').map { |id| id['id'] }
      ids.each_slice(1000) do |slice|
        LogLine.where(id: slice).delete_all
      end

      ids = Metric.connection.select_all('SELECT id FROM metrics WHERE run_id NOT IN (SELECT id FROM runs)').map { |id| id['id'] }
      Metric.where(id: ids).delete_all

      ids = WebhookDelivery.connection.select_all('SELECT id FROM webhook_deliveries WHERE run_id NOT IN (SELECT id FROM runs)').map { |id| id['id'] }
      WebhookDelivery.where(id: ids).delete_all

      ids = WebhookDelivery.connection.select_all('SELECT id FROM webhook_deliveries WHERE webhook_id NOT IN (SELECT id FROM webhooks)').map { |id| id['id'] }
      WebhookDelivery.where(id: ids).delete_all
    end
  end
end
