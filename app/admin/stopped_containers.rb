ActiveAdmin.register_page 'Stopped Containers' do
  content do
    table do
      thead do
        tr do
          th 'Container ID'
          th 'Exit code'
          th 'Finished at'
          th 'OOM Killed'
          th 'Run ID'
          th 'Scraper name'
          th 'Running'
          th 'Auto'
        end
      end

      tbody do
        records = Morph::DockerUtils.stopped_containers.each do |container|
          run = Morph::Runner.run_for_container(container)
          record = {
            container_id: container.json['Id'][0..11],
            exit_code: container.json['State']['ExitCode'],
            finished_at: Time.parse(container.json['State']['FinishedAt']).getlocal.strftime('%c'),
            oom_killed: container.json['State']['OOMKilled'] ? 'yes' : 'no'
          }
          if run
            record[:run_id] = run.id
            record[:scraper_name] = run.scraper.full_name if run.scraper
            record[:running] = run.running? ? 'yes' : 'no'
            record[:auto] = run.auto? ? 'yes' : 'no'
          end
          tr do
            td record[:container_id]
            td record[:exit_code]
            td record[:finished_at]
            td record[:oom_killed]
            td record[:run_id]
            td record[:scraper_name]
            td record[:running]
            td record[:auto]
          end
        end
      end
    end
    ul do
    end
  end
end
