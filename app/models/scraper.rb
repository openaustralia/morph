class Scraper < ActiveRecord::Base
  belongs_to :owner, class_name: User
  has_many :runs

  extend FriendlyId
  friendly_id :full_name, use: :finders

  def owned_by?(user)
    owner == user
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

  def destroy_repo_and_data
    FileUtils::rm_rf repo_path
    FileUtils::rm_rf data_path
  end

  def repo_path
    "db/scrapers/repos/#{full_name}"
  end

  def data_path
    "db/scrapers/data/#{full_name}"
  end

  def self.docker_image_name
    "scraper"
  end

  def self.build_docker_image!
    system("docker build -t=scraper lib/build_docker_image")
    # TODO On Linux we'll have access to the "docker" command line which can show standard out which
    # would be very helpful. As far as I can tell this is not currently possible with the docker api gem.

    # TODO Move these Docker setup bits to an initializer
    #Docker.validate_version!
    # Set read timeout to a silly 30 minutes (we'll need a bit of time to build an image)
    #Docker.options[:read_timeout] = 1800

    #puts "Building docker image (this is likely to take a while)..."
    #image = Docker::Image.build_from_dir("lib/build_docker_image") {|c| puts c}
    #image.tag(repo: docker_image_name, force: true)
  end

  def running?
    if last_run
      last_run.started_at && last_run.finished_at.nil?
    else
      false
    end
  end

  def queued?
    if last_run
      last_run.queued_at && last_run.started_at.nil?
    else
      false
    end
  end

  def last_run
    runs.order(queued_at: :desc).first
  end

  # Only return the last *completed* run
  def last_run_completed
    runs.where("finished_at IS NOT NULL").order(queued_at: :desc).first
  end

  def started_at
    last_run.started_at
  end

  def queued_at
    last_run.queued_at
  end

  def last_run_at
    last_run_completed.started_at if last_run_completed
  end

  def last_run_successful?
    last_run_status_code == 0
  end

  def last_run_status_code
    last_run_completed.status_code if last_run_completed
  end

  def queue!
    run = runs.create(queued_at: Time.now)
    self.delay.go2(run)
  end

  def clear
    FileUtils.rm sqlite_db_path
  end

  def sqlite_db_path
    "#{data_path}/scraperwiki.sqlite"
  end

  def sql_query(query)
    db = SQLite3::Database.new(sqlite_db_path, results_as_hash: true, type_translation: true, readonly: true)
    db.execute(query)
  end

  def sql_query_safe(query)
    begin
      sql_query(query)
    rescue SQLite3::CantOpenException, SQLite3::SQLException
      nil
    end
  end

  # The main section of the scraper running that is run in the background
  def go2(run)
    run.update_attributes(started_at: Time.now)
    synchronise_repo
    FileUtils.mkdir_p data_path

    c = Docker::Container.create("Cmd" => ['/bin/bash','-l','-c','ruby /repo/scraper.rb'],
      "User" => "scraper",
      "Image" => Scraper.docker_image_name)
    # TODO the local path will be different if docker isn't running through Vagrant (i.e. locally)
    # HACK to detect vagrant installation in crude way
    if Rails.root.to_s =~ /\/var\/www/
      local_root_path = Rails.root
    else
      local_root_path = "/vagrant"
    end
    # TODO Run this in the background
    # TODO Capture output to console
    c.start("Binds" => [
      "#{local_root_path}/#{repo_path}:/repo:ro",
      "#{local_root_path}/#{data_path}:/data"
    ])
    puts "Running docker container..."
    log_line_number = 0
    c.attach(logs: true) do |s,c|
      run.log_lines.create(stream: s, text: c, number: log_line_number)
      log_line_number += 1
    end
    # Scraper should already have finished now. We're just using this to return the scraper status code
    status_code = c.wait["StatusCode"]
    run.update_attributes(status_code: status_code, finished_at: Time.now)
    # TODO Clean up stopped container
  end
end
