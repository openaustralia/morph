class Run < ActiveRecord::Base
  belongs_to :scraper, inverse_of: :runs, touch: true
  has_many :log_lines
  has_one :metric

  delegate :data_path, :repo_path, :owner, :name, :git_url, :current_revision_from_repo,
    :full_name, :language, :main_scraper_filename, :database, to: :scraper

  def wall_time
    if started_at && finished_at
      finished_at - started_at
    else
      0
    end
  end

  def queued?
    queued_at && started_at.nil?
  end

  def running?
    started_at && finished_at.nil?
  end

  def finished?
    !!finished_at
  end

  def finished_with_errors?
    finished? && !finished_successfully?
  end

  def errors_in_logs?
    log_lines.to_a.count{|l| l.stream == "stderr"} > 0
  end

  def finished_successfully?
    # PHP doesn't seem to set the exit status to non-zero if there is a warning.
    # So, will say that things are successful if there are no errors in the log as well
    finished? && status_code == 0 && !errors_in_logs?
  end

  def self.time_output_filename
    "time.output"
  end

  def time_output_path
    File.join(data_path, Run.time_output_filename)
  end

  def docker_container_name
    owner.to_param + "_" + name
  end

  def scraper_command
    case language
    when :ruby
      "ruby /repo/#{main_scraper_filename}"
    when :php
      "php /repo/#{main_scraper_filename}"
    when :python
      "python /repo/#{main_scraper_filename}"
    end
  end

  def docker_image
    "openaustralia/morph-#{language}"
  end

  def language_supported?
    [:ruby, :php, :python].include?(language)
  end

  # Only knows about docker stuff for running
  def docker_run(options)
    Docker.options[:read_timeout] = 3600

    # This will fail if there is another container with the same name
    c = Docker::Container.create("Cmd" => ['/bin/bash', '-l', '-c', options[:command]],
      "User" => "scraper",
      "Image" => options[:image_name],
      "name" => options[:container_name])

    # TODO the local path will be different if docker isn't running through Vagrant (i.e. locally)
    # HACK to detect vagrant installation in crude way
    if Rails.root.to_s =~ /\/var\/www/
      local_root_path = Rails.root
    else
      local_root_path = "/vagrant"
    end

    begin
      c.start("Binds" => [
        "#{local_root_path}/#{options[:repo_path]}:/repo:ro",
        "#{local_root_path}/#{options[:data_path]}:/data"
      ])
      puts "Running docker container..."
      c.attach(logs: true) do |s,c|
        p s
        p c
        yield s,c
      end
    ensure
      c.kill if c.json["State"]["Running"]
    end
    # Scraper should already have finished now. We're just using this to return the scraper status code
    status_code = c.wait["StatusCode"]

    # Clean up after ourselves
    c.delete

    status_code
  end

  # The main section of the scraper running that is run in the background
  def synch_and_go!
    synchronise_repo
    update_attributes(started_at: Time.now, git_revision: current_revision_from_repo)
    FileUtils.mkdir_p data_path

    unless language_supported?
      log_lines.create(stream: "stderr", text: "Can't find scraper code", number: 0)
      update_attributes(status_code: 999, finished_at: Time.now)
      return
    end

    log_line_number = 0
    command = Metric.command(scraper_command, Run.time_output_filename)
    status_code = docker_run(command: command, image_name: docker_image, container_name: docker_container_name,
      repo_path: repo_path, data_path: data_path) do |s,c|
        log_lines.create(stream: s, text: c, number: log_line_number)
        log_line_number += 1
    end

    # Now collect and save the metrics
    metric = Metric.read_from_file(time_output_path)
    metric.update_attributes(run_id: self.id)

    update_attributes(status_code: status_code, finished_at: Time.now)
    database.tidy_data_path
  end

  def synchronise_repo
    # Set git timeout to 1 minute
    # TODO Move this to a configuration
    Grit::Git.git_timeout = 60
    gritty = Grit::Git.new(repo_path)
    if gritty.exist?
      puts "Pulling git repo #{repo_path}..."
      # TODO Fix this. Using grit seems to do a pull but not update the working directory
      # So falling back to shelling out to the git command
      #gritty = Grit::Repo.new(repo_path).git
      #puts gritty.pull({:raise => true}, "origin", "master")
      system("cd #{repo_path}; git pull")
    else
      puts "Cloning git repo #{git_url}..."
      puts gritty.clone({:verbose => true, :progress => true, :raise => true}, git_url, repo_path)
    end
    # Handle submodules. Always do this
    system("cd #{repo_path}; git submodule init")
    system("cd #{repo_path}; git submodule update")
  end
end
