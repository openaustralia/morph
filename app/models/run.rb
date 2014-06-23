class Run < ActiveRecord::Base
  include Sync::Actions
  belongs_to :owner
  belongs_to :scraper, inverse_of: :runs, touch: true
  has_many :log_lines
  has_one :metric
  has_many :connection_logs

  delegate :git_url, :full_name, to: :scraper
  delegate :current_revision_from_repo, to: :scraper, allow_nil: true
  delegate :utime, :stime, to: :metric

  def database
    Morph::Database.new(data_path)
  end

  def cpu_time
    utime + stime
  end

  def language
    Morph::Language.language(repo_path)
  end

  def finished_at=(time)
    write_attribute(:finished_at, time)
    update_wall_time
  end

  def update_wall_time
    if started_at && finished_at
      write_attribute(:wall_time, finished_at - started_at)
    end
  end

  def wall_time=(t)
    raise "Can't set wall_time directly"
  end

  def name
    if scraper
      scraper.name
    else
      # This run is using uploaded code and so is not associated with a scraper
      "run"
    end
  end

  def data_path
    "#{owner.data_root}/#{name}"
  end

  def repo_path
    "#{owner.repo_root}/#{name}"
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

  def error_text
    log_lines.where(stream: "stderr").order(:number).map{|l| l.text}.join
  end

  def finished_successfully?
    finished? && status_code == 0
  end

  def self.time_output_filename
    "time.output"
  end

  def time_output_path
    File.join(data_path, Run.time_output_filename)
  end

  def docker_container_name
    Morph::ContainerCompiler.docker_container_name(self)
  end

  def git_revision_github_url
    "https://github.com/#{full_name}/commit/#{git_revision}"
  end

  def go_with_logging
    puts "Starting...\n"
    database.backup
    update_attributes(started_at: Time.now, git_revision: current_revision_from_repo)
    sync_update scraper if scraper
    FileUtils.mkdir_p data_path
    FileUtils.chmod 0777, data_path

    unless Morph::Language.language_supported?(language)
      supported_scraper_files = Morph::Language.languages_supported.map do |l|
        Morph::Language.language_to_scraper_filename(l)
      end.to_sentence(last_word_connector: ", or ")
      yield "stderr", "Can't find scraper code. Expected to find a file called " +
         supported_scraper_files + " in the root directory"
      update_attributes(status_code: 999, finished_at: Time.now)
      return
    end

    if owner.buildpacks
      status_code = Morph::ContainerCompiler.compile_and_run_with_buildpacks(self) do |on|
        on.log {|s,c| yield s,c}
        on.ip_address do |ip|
          # Store the ip address of the container for this run
          update_attributes(ip_address: ip)
        end
      end
    else
      status_code = Morph::ContainerCompiler.compile_and_run_original(self) do |on|
        on.log {|s,c| yield s,c}
        on.ip_address do |ip|
          # Store the ip address of the container for this run
          update_attributes(ip_address: ip)
        end
      end
    end

    # Hack to not try to get metric if the compile failed
    if status_code != 255
      # Now collect and save the metrics
      metric = Metric.read_from_file(time_output_path)
      metric.update_attributes(run_id: self.id)
    end

    update_attributes(status_code: status_code, finished_at: Time.now)
    # Update information about what changed in the database
    diffstat = Morph::Database.diffstat(database.sqlite_db_backup_path, database.sqlite_db_path)
    tables = diffstat[:tables][:counts]
    records = diffstat[:records][:counts]
    update_attributes(
      tables_added: tables[:added],
      tables_removed: tables[:removed],
      tables_changed: tables[:changed],
      tables_unchanged: tables[:unchanged],
      records_added: records[:added],
      records_removed: records[:removed],
      records_changed: records[:changed],
      records_unchanged: records[:unchanged]
    )
    Morph::Database.tidy_data_path(data_path)
    if scraper
      scraper.update_sqlite_db_size
      scraper.reload
      sync_update scraper
    end
  end

  def stop!
    Morph::DockerRunner.stop(docker_container_name)
  end

  def log(stream, text)
    puts "#{stream}: #{text}"
    number = log_lines.maximum(:number) || 0
    line = log_lines.create(stream: stream.to_s, text: text, number: (number + 1))
    sync_new line, scope: self
  end

  def go!
    go_with_logging do |s,c|
      log(s, c)
    end
  end

  # The main section of the scraper running that is run in the background
  def synch_and_go!
    # If this run belongs to a scraper that has just been deleted then don't do anything
    if scraper
      Morph::Github.synchronise_repo(repo_path, git_url)
      go!
    end
  end
end
