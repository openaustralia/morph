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
  delegate :utime, :stime, :cpu_time, to: :metric

  # TODO: Run requires an owner - add a validation for that

  def database
    Morph::Database.new(data_path)
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

  # TODO: Put env in path so development and test don't crash into each other
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

  # Defining finished recently as finished within the last 48 hours. This is
  # because an auto-run scraper will run at a random time in a 24 hour interval.
  # So, given that we might be looking at any time within one of those 24 hour
  # cycles we need to look back at least 48 hours to ensure that we see all
  # possible scrapers that could be auto-run.
  def finished_recently?
    finished_at && finished_at > 48.hours.ago
  end

  def error_text
    log_lines.where(stream: 'stderr').order('log_lines.id').map(&:text).join
  end

  def git_revision_github_url
    "https://github.com/#{full_name}/commit/#{git_revision}"
  end

  def variables
    # Handle this run not having a scraper attached (run from morph-cli)
    scraper ? scraper.variables : []
  end

  # Returns a hash of environment variables
  def env_variables
    Variable.to_hash(variables)
  end

  # Called when a run has finished. Perform any post-run work here.
  def finished!
    return unless scraper.present?
    scraper.update_sqlite_db_size
    scraper.reindex
    scraper.reload
    scraper.deliver_webhooks(self)
  end
end
