class Scraper < ActiveRecord::Base
  belongs_to :owner
  has_many :runs
  has_many :metrics, through: :runs
  belongs_to :forked_by, class_name: "User"

  validates :scraperwiki_url, format: { with: /\Ahttps:\/\/classic.scraperwiki.com\/scrapers\/([-\w]+)(\/)?\z/,
    message: "Should be a valid ScraperWiki scraper url" }, allow_nil: true

  extend FriendlyId
  friendly_id :full_name, use: :finders

  # For successful runs calculates the average wall clock time that this scraper takes
  # Handy for the user to know how long it should expect to run for
  # Returns nil if not able to calculate this
  # TODO Refactor this using scopes
  def average_successful_wall_time
    successful_runs = runs.all.find_all{|r| r.finished_successfully?}
    successful_runs.sum(&:wall_time) / successful_runs.count if successful_runs.count > 0
  end

  # Let's say a scraper requires attention if it's set to run automatically and the last run failed
  def requires_attention?
    auto_run && last_run && last_run.finished_with_errors?
  end

  def total_wall_time
    runs.all.sum(&:wall_time)
  end

  def can_write?(user)
    user && (owner == user || user.organizations.include?(owner))
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
  end

  def readme
    f = Dir.glob(File.join(repo_path, "README*")).first
    if f
      GitHub::Markup.render(f, File.read(f)).html_safe
    end
  end

  def runnable?
    last_run.nil? || last_run.finished?
  end

  def last_run
    runs.order(queued_at: :desc).first
  end

  # Set auto to true if this job is being queued automatically (i.e. not directly by a person)
  def queue!(auto = false)
    # Guard against more than one of a particular scraper running at the same time
    runs.create(queued_at: Time.now, auto: auto).delay.go! if runnable?
  end

  def github_url_for_file(file)
    github_url + "/blob/master/" + file
  end

  def main_scraper_filename
    Scraper.language_to_scraper_filename(language)
  end

  def github_url_main_scraper_file
    github_url_for_file(main_scraper_filename)
  end

  def database
    Database.new(self)
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
    m = scraperwiki_url.match(/https:\/\/classic.scraperwiki.com\/scrapers\/([-\w]+)(\/)?/)
    m[1] if m
  end

  def current_revision_from_repo
    r = Grit::Repo.new(repo_path)
    Grit::Head.current(r).commit.id
  end

  # Defines our naming convention for the scraper of each language
  def self.language_to_file_extension(language)
    case language
    when :ruby
      "rb"
    when :php
      "php"
    when :python
      "py"
    end
  end

  def self.language_to_scraper_filename(language)
    "scraper.#{language_to_file_extension(language)}" if language
  end

  # Based on the scraper code figure out which language this scraper is
  def language
    [:ruby, :python, :php].find do |language|
      File.exists?(File.join(repo_path, Scraper.language_to_scraper_filename(language)))
    end
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

  def fork_from_scraperwiki!
    client = forked_by.octokit_client

    # We need to set auto_init so that we can create a commit later. The API doesn't support
    # adding a commit to an empty repository
    begin
      if forked_by == owner
        repo = client.create_repository(name, auto_init: true)
      else
        repo = client.create_repository(name, auto_init: true, organization: owner.nickname)
      end
      update_attributes(github_id: repo.id, github_url: repo.rels[:html].href, git_url: repo.rels[:git].href)
    rescue Octokit::UnprocessableEntity
      # This means the repo has already been created. We will have gotten here if this background job failed at some
      # point past here and is rerun. So, let's happily continue
    end

    scraperwiki = Scraperwiki.new(scraperwiki_shortname)

    # Copy the sqlite database across from Scraperwiki
    database.write_sqlite_database(scraperwiki.sqlite_database)
    # Rename the main table in the sqlite database
    database.standardise_table_name("swdata")

    # Fill in description
    repo = client.edit_repository(full_name, description: scraperwiki.title)
    self.update_attributes(description: scraperwiki.title)

    files = {
      Scraper.language_to_scraper_filename(scraperwiki.language) => scraperwiki.code,
      ".gitignore" => "# Ignore output of scraper\n#{Database.sqlite_db_filename}\n",
    }
    files["README.textile"] = scraperwiki.description unless scraperwiki.description.blank?
    add_commit_to_root_on_github(forked_by, files, "Fork of code from ScraperWiki at #{scraperwiki_url}")

    # Add another commit (but only if necessary) to translate the code so it runs here
    unless scraperwiki.translated_code == scraperwiki.code
      add_commit_to_master_on_github(forked_by, {Scraper.language_to_scraper_filename(scraperwiki.language) => scraperwiki.translated_code},
        "Automatic update to make ScraperWiki scraper work on Morph")
    end

    # Forking has finished
    update_attributes(forking: false)

    # TODO Make each background step idempotent so that failures can be retried

    # TODO Add repo link
    # TODO Copy across run interval from scraperwiki
    # TODO Check that it's a ruby scraper
    # TODO Add support for non-ruby scrapers
    # TODO Record progress (so that it can be shown in the UI)
  end
end
