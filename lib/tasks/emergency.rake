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

    desc "Delete duplicate enqueued Sidekiq scraper jobs. Sidekiq should be stopped for this to be effective"
    task delete_duplicate_scraper_jobs: :environment do
      queue = Sidekiq::Queue["scraper"].to_a
      queue.each do |x|
        if queue.count { |y| x.item["args"].first == y.item["args"].first } > 1
          puts "Deleting duplicate job for run ID: #{x.item["args"].first}..."
          x.delete
        end
      end
    end

    # See https://github.com/openaustralia/morph/issues/1038
    desc "Removed records from other tables associated with deleted scrapers"
    task fix_referential_integrity: :environment do
      def destroy_by_id(model, ids)
        progressbar = ProgressBar.create(title: model.name.pluralize, total: ids.count, format: "%t: |%B| %E")
        ids.each do |id|
          model.find(id).destroy
          progressbar.increment
        end
      end

      ids = Alert.connection.select_all("SELECT id FROM alerts WHERE watch_type = 'Scraper' AND watch_id NOT IN (SELECT id FROM scrapers)").map{|id| id["id"]}
      destroy_by_id(Alert, ids)

      ids = ApiQuery.connection.select_all("SELECT id FROM api_queries WHERE scraper_id NOT IN (SELECT id FROM scrapers)").map{|id| id["id"]}
      destroy_by_id(ApiQuery, ids)

      ids = Contribution.connection.select_all("SELECT id FROM contributions WHERE scraper_id NOT IN (SELECT id FROM scrapers)").map{|id| id["id"]}
      destroy_by_id(Contribution, ids)

      ids = Run.connection.select_all("SELECT id FROM runs WHERE scraper_id NOT IN (SELECT id FROM scrapers)").map{|id| id["id"]}
      destroy_by_id(Run, ids)

      ids = Variable.connection.select_all("SELECT id FROM variables WHERE scraper_id NOT IN (SELECT id FROM scrapers)").map{|id| id["id"]}
      destroy_by_id(Variable, ids)

      ids = Webhook.connection.select_all("SELECT id FROM webhooks WHERE scraper_id NOT IN (SELECT id FROM scrapers)").map{|id| id["id"]}
      destroy_by_id(Webhook, ids)

      ids = ConnectionLog.connection.select_all("SELECT id FROM connection_logs WHERE run_id NOT IN (SELECT id FROM runs)").map{|id| id["id"]}
      ConnectionLog.where(id: ids).delete_all

      ids = LogLine.connection.select_all("SELECT id FROM log_lines WHERE run_id NOT IN (SELECT id FROM runs)").map{|id| id["id"]}
      LogLine.where(id: ids).delete_all

      ids = Metric.connection.select_all("SELECT id FROM metrics WHERE run_id NOT IN (SELECT id FROM runs)").map{|id| id["id"]}
      Metric.where(id: ids).delete_all

      ids = WebhookDelivery.connection.select_all("SELECT id FROM webhook_deliveries WHERE run_id NOT IN (SELECT id FROM runs)").map{|id| id["id"]}
      WebhookDelivery.where(id: ids).delete_all

      ids = WebhookDelivery.connection.select_all("SELECT id FROM webhook_deliveries WHERE webhook_id NOT IN (SELECT id FROM webhooks)").map{|id| id["id"]}
      WebhookDelivery.where(id: ids).delete_all
    end
  end
end
