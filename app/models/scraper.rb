class Scraper < ActiveRecord::Base
  belongs_to :owner, class_name: User
  has_many :runs

  extend FriendlyId
  friendly_id :full_name, use: :finders

  delegate :queued_at, :started_at, :finished_at, :status_code, to: :last_run

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
    has_run? && started_at && finished_at.nil?
  end

  def queued?
    has_run? && queued_at && started_at.nil?
  end

  def finished?
    has_run? && finished_at
  end

  def finished_successfully?
    finished? && status_code == 0
  end

  def finished_with_errors?
    finished? && status_code != 0
  end

  def has_run?
    !!last_run
  end

  def last_run
    runs.order(queued_at: :desc).first
  end

  def queue!
    # Guard against more than one of a particular scraper running at the same time
    if !has_run? || finished?
      run = runs.create(queued_at: Time.now)
      self.delay.go(run)
    end
  end

  def clear
    FileUtils.rm sqlite_db_path
  end

  def sqlite_db_path
    "#{data_path}/scraperwiki.sqlite"
  end

  def sql_query(query)
    db = SQLite3::Database.new(sqlite_db_path, results_as_hash: true, type_translation: true, readonly: true)
    # If database is busy wait 5s
    db.busy_timeout(5000)
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
  def go(run)
    run.update_attributes(started_at: Time.now)
    synchronise_repo
    FileUtils.mkdir_p data_path

    Docker.options[:read_timeout] = 3600

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

    begin
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
    ensure
      c.kill if c.json["State"]["Running"]
    end
    # Scraper should already have finished now. We're just using this to return the scraper status code
    status_code = c.wait["StatusCode"]
    run.update_attributes(status_code: status_code, finished_at: Time.now)
    # TODO Clean up stopped container
  end

  def scraperwiki_shortname
    # scraperwiki_url should be of the form https://classic.scraperwiki.com/scrapers/shortname/
    m = scraperwiki_url.match(/https:\/\/classic.scraperwiki.com\/scrapers\/(\w+)(\/)?/)
    m[1] if m
  end

  def get_scraperwiki_info
    url = "https://api.scraperwiki.com/api/1.0/scraper/getinfo?format=jsondict&name=#{scraperwiki_shortname}&version=-1&quietfields=runevents%7Chistory%7Cdatasummary%7Cuserroles"
    response = Faraday.get url
    JSON.parse(response.body).first
  end

  def fork_from_scraperwiki!
    client = Octokit::Client.new :access_token => owner.access_token

    # We need to set auto_init so that we can create a commit later. The API doesn't support
    # adding a commit to an empty repository
    begin
      repo = client.create_repository(name, auto_init: true)
      update_attributes(github_id: repo.id, github_url: repo.rels[:html].href, git_url: repo.rels[:git].href)
    rescue Octokit::UnprocessableEntity
      # This means the repo has already been created. We will have gotten here if this background job failed at some
      # point past here and is rerun. So, let's happily continue
    end

    v = get_scraperwiki_info
    code = v["code"]
    description = v["title"]
    readme_text = v["description"]

    # Copy the sqlite database across from Scraperwiki
    url = "https://classic.scraperwiki.com/scrapers/export_sqlite/#{scraperwiki_shortname}/"
    response = Faraday.get(url)
    sqlite_db = response.body
    if sqlite_db =~ /The dataproxy connection timed out, please retry./
      raise response.body
    end
    FileUtils.mkdir_p data_path
    File.open(sqlite_db_path, 'wb') {|file| file.write(sqlite_db) }

    # Fill in description
    repo = client.edit_repository(full_name, description: description)
    self.update_attributes(description: description)

    gitignore_contents = <<-EOF
# Ignore output of scraper
scraperwiki.sqlite
    EOF
    blobs =  [
      {
        :path => "scraper.rb",
        :mode => "100644",
        :type => "blob",
        :content => code
      },
      {
        :path => ".gitignore",
        :mode => "100644",
        :type => "blob",
        :content => gitignore_contents       
      }
    ]
    unless readme_text.blank?
      blobs += {
        :path => "README.md",
        :mode => "100644",
        :type => "blob",
        :content => readme_text
      }
    end
    # Commit the code
    tree = client.create_tree(full_name, blobs)
    commit_message = "Fork of code from ScraperWiki at #{scraperwiki_url}"
    commit = client.create_commit(full_name, commit_message, tree.sha)
    client.update_ref(full_name,"heads/master", commit.sha)

    # Now add an extra commit that adds "require 'scraperwiki'" to the top of the scraper code
    # but only if it's necessary
    unless code =~ /require ['"]scraperwiki['"]/
      tree2 = client.create_tree(full_name, [
        {
          :path => "scraper.rb",
          :mode => "100644",
          :type => "blob",
          :content => "require 'scraperwiki'\n" + code
        },
      ], :base_tree => tree.sha)
      commit2 = client.create_commit(full_name, "Add require 'scraperwiki'", tree2.sha, commit.sha)
      client.update_ref(full_name,"heads/master", commit2.sha)
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
