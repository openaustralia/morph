class Run < ActiveRecord::Base
  belongs_to :scraper
  has_many :log_lines
  belongs_to :metric

  delegate :data_path, :repo_path, :owner, :name, :git_url, to: :scraper

  def finished?
    !!finished_at
  end

  def finished_successfully?
    finished? && status_code == 0
  end

  def finished_with_errors?
    finished? && status_code != 0
  end

  def self.time_output_filename
    "time.output"
  end

  def self.docker_image_name
    "scraper"
  end

  def time_output_path
    File.join(data_path, Run.time_output_filename)
  end

  def docker_container_name
    owner.to_param + "_" + name
  end

  # The main section of the scraper running that is run in the background
  def go!
    update_attributes(started_at: Time.now)
    synchronise_repo
    FileUtils.mkdir_p data_path

    Docker.options[:read_timeout] = 3600

    # This will fail if there is another container with the same name
    command = Metric.command('ruby /repo/scraper.rb', Run.time_output_filename)
    c = Docker::Container.create("Cmd" => ['/bin/bash', '-l', '-c', command],
      "User" => "scraper",
      "Image" => Run.docker_image_name,
      "name" => docker_container_name)
      # TODO the local path will be different if docker isn't running through Vagrant (i.e. locally)
      # HACK to detect vagrant installation in crude way
    if Rails.root.to_s =~ /\/var\/www/
      local_root_path = Rails.root
    else
      local_root_path = "/vagrant"
    end

    begin
      c.start("Binds" => [
        "#{local_root_path}/#{repo_path}:/repo:ro",
        "#{local_root_path}/#{data_path}:/data"
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
    metric = Metric.read_from_file(time_output_path)

    update_attributes(status_code: status_code, metric_id: metric.id, finished_at: Time.now)
    tidy_data_path
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
  end

  # Remove any files or directories in the data_path that are not the actual database
  def tidy_data_path
    # First get all the files in the data directory
    filenames = Dir.entries(data_path)
    filenames.delete(".")
    filenames.delete("..")
    filenames.delete(Scraper.sqlite_db_filename)
    FileUtils.rm_rf filenames.map{|f| File.join(data_path, f)}
  end
end
