ActiveAdmin.register_page 'Queue' do
  content do
    # Get runs that have a background worker
    workers = Sidekiq::Workers.new
    active_runs = workers.collect do |process_id, thread_id, work|
      if work["queue"] == "scraper"
        {
          run: Run.find(work["payload"]["args"].first),
          enqueued_at: Time.at(work["payload"]["enqueued_at"]),
          run_at: Time.at(work['run_at'])
        }
      end
    end.compact

    h1 "#{active_runs.count} active"
    unless active_runs.empty?
      table do
        thead do
          tr do
            th 'Run ID'
            th 'Scraper name'
            th 'Enqueued'
            th 'Started'
          end
        end

        tbody do
          active_runs.each do |record|
            scraper = record[:run].scraper
            tr do
              td link_to record[:run].id, admin_run_path(record[:run])
              td link_to scraper.full_name, scraper
              td time_ago_in_words(record[:enqueued_at]) + ' ago'
              td time_ago_in_words(record[:run_at]) + ' ago'
            end
          end
        end
      end
    end

    h1 "#{Sidekiq::Queue["scraper"].size} enqueued"
  end
end
