class Scraper < ActiveRecord::Base
  belongs_to :owner, inverse_of: :scrapers
  has_many :runs, inverse_of: :scraper
  has_many :metrics, through: :runs
  belongs_to :forked_by, class_name: "User"
  validates :name, format: { with: /\A[a-zA-Z0-9_-]+\z/, message: "can only have letters, numbers, '_' and '-'" }
  has_one :last_run, -> { order "queued_at DESC" }, class_name: "Run"

  extend FriendlyId
  friendly_id :full_name, use: :finders

  delegate :queued?, :running?, to: :last_run, allow_nil: true

  # Given a scraper name on github populates the fields for a morph scraper but doesn't save it
  def self.new_from_github(full_name)
    repo = Octokit.repository(full_name)
    repo_owner = Owner.find_by_nickname(repo.owner.login)
    # Populate a new scraper with information from the repo
    Scraper.new(name: repo.name, full_name: repo.full_name,
      description: repo.description, github_id: repo.id, owner_id: repo_owner.id,
      github_url: repo.rels[:html].href, git_url: repo.rels[:git].href)
  end

  def successful_runs
    runs.includes(:log_lines).order(finished_at: :desc).select{|r| r.finished_successfully?}
  end

  def latest_successful_run_time
    latest_successful_run = successful_runs.first
    latest_successful_run.finished_at if latest_successful_run
  end

  def finished_runs
    runs.where("finished_at IS NOT NULL").order(finished_at: :desc)
  end

  # For successful runs calculates the average wall clock time that this scraper takes
  # Handy for the user to know how long it should expect to run for
  # Returns nil if not able to calculate this
  # TODO Refactor this using scopes
  def average_successful_wall_time
    successful_runs.sum(&:wall_time) / successful_runs.count if successful_runs.count > 0
  end

  def queued_or_running?
    queued? || running?
  end

  # Let's say a scraper requires attention if it's set to run automatically and the last run failed
  def requires_attention?
    auto_run && last_run && last_run.finished_with_errors?
  end

  def total_wall_time
    runs.to_a.sum(&:wall_time)
  end

  def self.can_write?(user, owner)
    user && (owner == user || user.organizations.include?(owner))
  end

  def can_write?(user)
    Scraper.can_write?(user, owner)
  end

  def destroy_repo_and_data
    FileUtils::rm_rf repo_path
    FileUtils::rm_rf data_path
  end

  def repo_path
    "#{owner.repo_root}/#{name}"
  end

  def data_path
    "#{owner.data_root}/#{name}"
  end

  def utime
    metrics.sum(:utime)
  end

  def stime
    metrics.sum(:stime)
  end

  def cpu_time
    utime + stime
  end

  def self.update_docker_image!
    docker_command = "docker #{ENV['DOCKER_TCP'] ? "-H #{ENV['DOCKER_TCP']}" : ""}"
    system("#{docker_command} pull openaustralia/morph-ruby")
    system("#{docker_command} pull openaustralia/morph-php")
    system("#{docker_command} pull openaustralia/morph-python")
  end

  def readme
    f = Dir.glob(File.join(repo_path, "README*")).first
    if f
      GitHub::Markup.render(f, File.read(f)).html_safe
    end
  end

  def readme_filename
    Pathname.new(Dir.glob(File.join(repo_path, "README*")).first).basename.to_s
  end

  def github_url_readme
    github_url_for_file(readme_filename)
  end

  def runnable?
    last_run.nil? || last_run.finished?
  end

  # Set auto to true if this job is being queued automatically (i.e. not directly by a person)
  def queue!(auto = false)
    # Guard against more than one of a particular scraper running at the same time
    if runnable?
      run = runs.create(queued_at: Time.now, auto: auto, owner_id: owner_id)
      RunWorker.perform_async(run.id) 
    end
  end

  def github_url_for_file(file)
    github_url + "/blob/master/" + file
  end

  def language
    l = Morph::Language.language(repo_path)
  end

  def main_scraper_filename
    Morph::Language.main_scraper_filename(repo_path)
  end

  def github_url_main_scraper_file
    github_url_for_file(main_scraper_filename)
  end

  def database
    Morph::Database.new(self)
  end
  
  # It seems silly implementing this
  def Scraper.directory_size(directory)
    r = 0
    # Ick
    files = Dir.entries(directory)
    files.delete(".")
    files.delete("..") 
    files.map{|f| File.join(directory, f)}.each do |f|
      s = File.lstat(f)
      if s.file?
        r += s.size
      else
        r += Scraper.directory_size(f)
      end
    end
    r
  end

  def total_disk_usage
    repo_size + database.sqlite_db_size
  end

  def repo_size
    if File.exists?(repo_path)
      Scraper.directory_size(repo_path)
    else
      0
    end
  end

  def scraperwiki_shortname
    # scraperwiki_url should be of the form https://classic.scraperwiki.com/scrapers/shortname/
    if scraperwiki_url
      m = scraperwiki_url.match(/https:\/\/classic.scraperwiki.com\/scrapers\/([-\w]+)(\/)?/)
      m[1] if m
    end
  end

  def scraperwiki_shortname=(shortname)
    self.scraperwiki_url = "https://classic.scraperwiki.com/scrapers/#{shortname}/" if shortname
  end

  def current_revision_from_repo
    r = Grit::Repo.new(repo_path)
    Grit::Head.current(r).commit.id
  end

  # files should be a hash of "filename" => "content"
  def add_commit_to_master_on_github(user, files, message)
    client = user.octokit_client
    blobs = files.map do |filename, content|
      {
        :path => filename,
        :mode => "100644",
        :type => "blob",
        :content => content
      }
    end

    # Let's get all the info about head
    ref = client.ref(full_name, "heads/master")
    commit_sha = ref.object.sha
    commit = client.commit(full_name, commit_sha)
    tree_sha = commit.commit.tree.sha

    tree2 = client.create_tree(full_name, blobs, :base_tree => tree_sha)
    commit2 = client.create_commit(full_name, message, tree2.sha, commit_sha)
    client.update_ref(full_name, "heads/master", commit2.sha)
  end

  # Overwrites whatever there was before in that repo
  # Obviously use with great care
  def add_commit_to_root_on_github(user, files, message)
    client = user.octokit_client
    blobs = files.map do |filename, content|
      {
        :path => filename,
        :mode => "100644",
        :type => "blob",
        :content => content
      }
    end
    tree = client.create_tree(full_name, blobs)
    commit = client.create_commit(full_name, message, tree.sha)
    client.update_ref(full_name, "heads/master", commit.sha)
  end

  # progress should be between 0 and 100
  def fork_progress(message, progress)
      update_attributes(forking_message: message, forking_progress: progress)
  end

  def synchronise_repo
    Morph::Github.synchronise_repo(repo_path, git_url)
  end

  # Return the https version of the git clone url (git_url)
  def git_url_https
    "https" + git_url[3..-1]
  end

  def fork_from_scraperwiki!
    client = forked_by.octokit_client

    # We need to set auto_init so that we can create a commit later. The API doesn't support
    # adding a commit to an empty repository
    begin
      fork_progress("Creating GitHub repository", 20)
      repo = Morph::Github.create_repository(forked_by, owner, name)
      update_attributes(github_id: repo.id, github_url: repo.rels[:html].href, git_url: repo.rels[:git].href)
    rescue Octokit::UnprocessableEntity
      # This means the repo has already been created. We will have gotten here if this background job failed at some
      # point past here and is rerun. So, let's happily continue
    end

    scraperwiki = Morph::Scraperwiki.new(scraperwiki_shortname)

    # Copy the sqlite database across from Scraperwiki
    fork_progress("Forking sqlite database", 40)
    database.write_sqlite_database(scraperwiki.sqlite_database)
    # Rename the main table in the sqlite database
    database.standardise_table_name("swdata")

    fork_progress("Forking code", 60)

    # Fill in description
    repo = client.edit_repository(full_name, description: scraperwiki.title,
      homepage: Rails.application.routes.url_helpers.scraper_url(self))
    self.update_attributes(description: scraperwiki.title)

    files = {
      Morph::Language.language_to_scraper_filename(scraperwiki.language) => scraperwiki.code,
      ".gitignore" => "# Ignore output of scraper\n#{Morph::Database.sqlite_db_filename}\n",
    }
    files["README.textile"] = scraperwiki.description unless scraperwiki.description.blank?
    add_commit_to_root_on_github(forked_by, files, "Fork of code from ScraperWiki at #{scraperwiki_url}")

    # Add another commit (but only if necessary) to translate the code so it runs here
    unless scraperwiki.translated_code == scraperwiki.code
      add_commit_to_master_on_github(forked_by, {Morph::Language.language_to_scraper_filename(scraperwiki.language) => scraperwiki.translated_code},
        "Automatic update to make ScraperWiki scraper work on Morph")
    end

    fork_progress("Synching repository", 80)
    synchronise_repo

    # Forking has finished
    fork_progress(nil, 100)
    update_attributes(forking: false)


    # TODO Add repo link
  end
end
