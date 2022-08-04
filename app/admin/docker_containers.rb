# typed: false
# frozen_string_literal: true

ActiveAdmin.register_page "Docker Containers" do
  content do
    workers = Sidekiq::Workers.new
    active_sidekiq_jobs = workers.collect do |_process_id, _thread_id, work|
      work["payload"]["args"].first if work["queue"] == "scraper"
    end.compact
    retrying_sidekiq_jobs = Sidekiq::RetrySet.new.collect do |job|
      job.args.first if job.klass == "RunWorker"
    end.compact

    records = Docker::Container.all(all: true).map do |container|
      run = Morph::Runner.run_for_container(container)
      info = container.json
      record = {
        container_id: info["Id"][0..11],
        running: info["State"]["Running"] ? "yes" : "no",
        started_at: Time.zone.parse(info["State"]["StartedAt"])
      }
      if record[:running] == "no"
        record[:exit_code] = info["State"]["ExitCode"]
        record[:finished_at] = Time.zone.parse(info["State"]["FinishedAt"])
        record[:oom_killed] = info["State"]["OOMKilled"] ? "yes" : "no"
      end
      if run
        record[:run_id] = run.id
        record[:scraper_name] = run.scraper.full_name if run.scraper
        record[:scraper_running] = run.running? ? "yes" : "no"
        record[:run_status_code] = run.status_code
        record[:auto] = run.auto? ? "yes" : "no"

        record[:active_sidekiq_job] = active_sidekiq_jobs.include?(run.id) ? "yes" : "no"
        record[:retrying_sidekiq_job] = retrying_sidekiq_jobs.include?(run.id) ? "yes" : "no"
      end
      record
    end

    # Show most recent record first
    running_records = records.select { |r| r[:running] == "yes" }
                             .sort { |a, b| b[:started_at] <=> a[:started_at] }
    stopped_records = records.select { |r| r[:running] == "no" }
                             .sort { |a, b| b[:finished_at] <=> a[:finished_at] }

    h1 "#{running_records.count} running"
    if running_records.present?
      table do
        thead do
          tr do
            th "Container ID"
            th "Running for"
            th "Run ID"
            th "Scraper name"
            th "Scraper running?"
            th "Active Sidekiq job?"
            th "Retrying Sidekiq job?"
            th "Auto"
          end
        end

        tbody do
          running_records.each do |record|
            tr do
              td record[:container_id]
              td time_ago_in_words(record[:started_at])
              td do
                link_to record[:run_id], admin_run_path(id: record[:run_id]) if record[:run_id]
              end
              td do
                link_to record[:scraper_name], scraper_path(id: record[:scraper_name]) if record[:scraper_name]
              end
              td record[:scraper_running]
              td record[:active_sidekiq_job]
              td record[:retrying_sidekiq_job]
              td record[:auto]
            end
          end
        end
      end
    end

    h1 "#{stopped_records.count} stopped"
    if stopped_records.present?
      table do
        thead do
          tr do
            th "Container ID"
            th "Exit code"
            th "Finished"
            th "Ran for"
            th "OOM Killed"
            th "Run ID"
            th "Scraper name"
            th "Scraper running?"
            th "Active Sidekiq job?"
            th "Retrying Sidekiq job?"
            th "Run status code"
            th "Auto"
          end
        end

        tbody do
          stopped_records.each do |record|
            tr do
              td record[:container_id]
              td record[:exit_code]
              td do
                "#{time_ago_in_words(record[:finished_at])} ago" if record[:finished_at]
              end
              td do
                distance_of_time_in_words(record[:finished_at] - record[:started_at]) if record[:finished_at]
              end
              td record[:oom_killed]
              td do
                link_to record[:run_id], admin_run_path(id: record[:run_id]) if record[:run_id]
              end
              td do
                link_to record[:scraper_name], scraper_path(id: record[:scraper_name]) if record[:scraper_name]
              end
              td record[:scraper_running]
              td record[:active_sidekiq_job]
              td record[:retrying_sidekiq_job]
              td record[:run_status_code]
              td record[:auto]
            end
          end
        end
      end
    end
  end
end
