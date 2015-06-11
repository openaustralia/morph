ActiveAdmin.register_page 'Containers' do
  content do
    records = Docker::Container.all(all: true).map do |container|
      run = Morph::Runner.run_for_container(container)
      info = container.json
      record = {
        container_id: info['Id'][0..11],
        running: info['State']['Running'] ? 'yes' : 'no',
        started_at: Time.parse(info['State']['StartedAt'])
      }
      if record[:running] == 'no'
        record[:exit_code] = info['State']['ExitCode']
        record[:finished_at] = Time.parse(info['State']['FinishedAt'])
        record[:oom_killed] = info['State']['OOMKilled'] ? 'yes' : 'no'
      end
      if run
        record[:run_id] = run.id
        record[:scraper_name] = run.scraper.full_name if run.scraper
        record[:scraper_running] = run.running? ? 'yes' : 'no'
        record[:run_status_code] = run.status_code
        record[:auto] = run.auto? ? 'yes' : 'no'
      end
      record
    end

    # Show most recent record first
    running_records = records.select { |r| r[:running] == 'yes' }
      .sort { |a, b| b[:started_at] <=> a[:started_at] }
    stopped_records = records.select { |r| r[:running] == 'no' }
      .sort { |a, b| b[:finished_at] <=> a[:finished_at] }

    unless running_records.empty?
      h1 "Running"
      table do
        thead do
          tr do
            th 'Container ID'
            th 'Run ID'
            th 'Scraper name'
            th 'Scraper running?'
            th 'Auto'
          end
        end

        tbody do
          running_records.each do |record|
            tr do
              td record[:container_id]
              td do
                if record[:run_id]
                  link_to record[:run_id], admin_run_path(id: record[:run_id])
                end
              end
              td do
                if record[:scraper_name]
                  link_to record[:scraper_name], scraper_path(id: record[:scraper_name])
                end
              end
              td record[:scraper_running]
              td record[:auto]
            end
          end
        end
      end
    end
    
    h1 "Stopped"
    table do
      thead do
        tr do
          th 'Container ID'
          th 'Exit code'
          th 'Finished'
          th 'Ran for'
          th 'OOM Killed'
          th 'Run ID'
          th 'Scraper name'
          th 'Scraper running?'
          th 'Run status code'
          th 'Auto'
        end
      end

      tbody do
        stopped_records.each do |record|
          tr do
            td record[:container_id]
            td record[:exit_code]
            td do
              if record[:finished_at]
                time_ago_in_words(record[:finished_at]) + ' ago'
              end
            end
            td do
              if record[:finished_at]
                distance_of_time_in_words(record[:finished_at] - record[:started_at])
              end
            end
            td record[:oom_killed]
            td do
              if record[:run_id]
                link_to record[:run_id], admin_run_path(id: record[:run_id])
              end
            end
            td do
              if record[:scraper_name]
                link_to record[:scraper_name], scraper_path(id: record[:scraper_name])
              end
            end
            td record[:scraper_running]
            td record[:run_status_code]
            td record[:auto]
          end
        end
      end
    end
  end
end
