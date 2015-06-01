# A run of a scraper
class Run < ActiveRecord::Base
  belongs_to :owner
  belongs_to :scraper, inverse_of: :runs, touch: true
  has_many :log_lines
  has_one :metric
  has_many :connection_logs
  has_many :domains, -> { distinct }, through: :connection_logs

  scope :finished_successfully, -> { where(status_code: 0) }
  scope :running, -> { where(finished_at: nil).where('started_at IS NOT NULL') }

  delegate :git_url, :full_name, :current_revision_from_repo,
           to: :scraper, allow_nil: true
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
    return if started_at.nil? || finished_at.nil?

    write_attribute(:wall_time, finished_at - started_at)
  end

  def wall_time=(_)
    fail "Can't set wall_time directly"
  end

  def name
    if scraper
      scraper.name
    else
      # This run is using uploaded code and so is not associated with a scraper
      'run'
    end
  end

  def data_path
    "#{owner.data_root}/#{name}"
  end

  def repo_path
    "#{owner.repo_root}/#{name}"
  end

  def queued?
    queued_at && started_at.nil? && finished_at.nil?
  end

  def running?
    started_at && finished_at.nil?
  end

  def finished?
    !!finished_at
  end

  def finished_successfully?
    status_code == 0
  end

  def finished_with_errors?
    status_code && status_code != 0
  end

  def finished_recently?
    finished_at && finished_at > 24.hours.ago
  end

  def error_text
    log_lines.where(stream: 'stderr').order(:number).map(&:text).join
  end

  def git_revision_github_url
    "https://github.com/#{full_name}/commit/#{git_revision}"
  end

  def synch_and_go!
    Morph::Runner.new(self).synch_and_go!
  end

  def go!
    Morph::Runner.new(self).go!
  end

  def go_with_logging
    Morph::Runner.new(self).go_with_logging do |s, c|
      yield s, c
    end
  end

  def log(stream, text)
    Morph::Runner.new(self).log(stream, text)
  end

  def stop!
    Morph::Runner.new(self).stop!
  end

  def docker_container_name
    Morph::Runner.new(self).docker_container_name
  end

  def container_for_run_exists?
    Morph::Runner.new(self).container_for_run_exists?
  end

  def variables
    # Handle this run not having a scraper attached (run from morph-cli)
    scraper ? scraper.variables : []
  end

  # Returns array of environment variables as key-value pairs
  def env_variables
    variables.map { |v| [v.name, v.value] }
  end
end
