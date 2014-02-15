class Run < ActiveRecord::Base
  belongs_to :owner
  belongs_to :scraper, inverse_of: :runs, touch: true
  has_many :log_lines
  has_one :metric

  delegate :git_url, :full_name, :database, to: :scraper
  delegate :current_revision_from_repo, to: :scraper, allow_nil: true

  def language
    Morph::Language.language(repo_path)
  end

  def wall_time
    if started_at && finished_at
      finished_at - started_at
    else
      0
    end
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
    "#{owner.to_param}_#{name}_#{id}"
  end

  def docker_image
    "openaustralia/morph-#{language}"
  end

  def go_with_logging
    puts "Starting...\n"
    update_attributes(started_at: Time.now, git_revision: current_revision_from_repo)
    FileUtils.mkdir_p data_path

    unless Morph::Language.language_supported?(language)
      yield "stderr", "Can't find scraper code"
      update_attributes(status_code: 999, finished_at: Time.now)
      return
    end

    command = Metric.command(Morph::Language.scraper_command(language), Run.time_output_filename)
    status_code = Morph::DockerRunner.run(command: command, image_name: docker_image, container_name: docker_container_name,
      repo_path: repo_path, data_path: data_path) do |s,c|
        yield s, c
    end

    # Now collect and save the metrics
    metric = Metric.read_from_file(time_output_path)
    metric.update_attributes(run_id: self.id)

    update_attributes(status_code: status_code, finished_at: Time.now)
    Morph::Database.tidy_data_path(data_path)
  end

  def log(stream, text)
    puts "#{stream}: #{text}"
    number = log_lines.maximum(:number) || 0
    log_lines.create(stream: stream, text: text, number: (number + 1))
  end

  def go!
    go_with_logging do |s,c|
      log(s, c)
    end
  end

  # The main section of the scraper running that is run in the background
  def synch_and_go!
    Morph::Github.synchronise_repo(repo_path, git_url)
    go!
  end
end
