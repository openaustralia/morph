class Run < ActiveRecord::Base
  belongs_to :scraper
  has_many :log_lines
  belongs_to :metric

  def finished?
    !!finished_at
  end

  def finished_successfully?
    finished? && status_code == 0
  end

  def finished_with_errors?
    finished? && status_code != 0
  end

  # The main section of the scraper running that is run in the background
  def go!
    update_attributes(started_at: Time.now)
    scraper.synchronise_repo
    FileUtils.mkdir_p scraper.data_path

    Docker.options[:read_timeout] = 3600

    # This will fail if there is another container with the same name
    command = Metric.command('ruby /repo/scraper.rb', scraper.time_output_filename)
    c = Docker::Container.create("Cmd" => ['/bin/bash', '-l', '-c', command],
      "User" => "scraper",
      "Image" => Scraper.docker_image_name,
      "name" => scraper.docker_container_name)
      # TODO the local path will be different if docker isn't running through Vagrant (i.e. locally)
      # HACK to detect vagrant installation in crude way
    if Rails.root.to_s =~ /\/var\/www/
      local_root_path = Rails.root
    else
      local_root_path = "/vagrant"
    end

    begin
      c.start("Binds" => [
        "#{local_root_path}/#{scraper.repo_path}:/repo:ro",
        "#{local_root_path}/#{scraper.data_path}:/data"
      ])
      puts "Running docker container..."
      log_line_number = 0
      c.attach(logs: true) do |s,c|
        log_lines.create(stream: s, text: c, number: log_line_number)
        log_line_number += 1
      end
    ensure
      c.kill if c.json["State"]["Running"]
    end
    # Scraper should already have finished now. We're just using this to return the scraper status code
    status_code = c.wait["StatusCode"]

    # Clean up after ourselves
    c.delete

    # Now collect and save the metrics
    metric = Metric.read_from_file(scraper.time_output_path)

    update_attributes(status_code: status_code, metric_id: metric.id, finished_at: Time.now)
    scraper.tidy_data_path
  end

end
