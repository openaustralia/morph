class Scraper < ActiveRecord::Base
  belongs_to :owner, class_name: User
  has_many :runs
  has_many :metrics, through: :runs
  validates :scraperwiki_url, format: { with: /\Ahttps:\/\/classic.scraperwiki.com\/scrapers\/([-\w]+)(\/)?\z/,
    message: "Should be a valid ScraperWiki scraper url" }, allow_nil: true

  extend FriendlyId
  friendly_id :full_name, use: :finders

  def owned_by?(user)
    owner == user
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

  def clear
    FileUtils.rm sqlite_db_path
  end

  def github_url_for_file(file)
    github_url + "/blob/master/" + file
  end

  def main_scraper_filename
    # TODO This will obviously be different for different languages
    "scraper.rb"
  end

  def github_url_main_scraper_file
    github_url_for_file(main_scraper_filename)
  end

  def self.sqlite_db_filename
    "data.sqlite"
  end

  def self.sqlite_table_name
    "data"
  end

  def sqlite_db_path
    File.join(data_path, Scraper.sqlite_db_filename)
  end

  def sql_query(query, readonly = true)
    db = SQLite3::Database.new(sqlite_db_path, results_as_hash: true, type_translation: true, readonly: readonly)
    # If database is busy wait 5s
    db.busy_timeout(5000)
    db.execute(query)
  end

  def sql_query_safe(query, readonly = true)
    begin
      sql_query(query, readonly)
    rescue SQLite3::CantOpenException, SQLite3::SQLException
      nil
    end
  end

  def no_rows
    sql_query_safe("select count(*) from #{Scraper.sqlite_table_name}").first.values.first
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
    repo_size + sqlite_db_size
  end

  def repo_size
    if File.exists?(repo_path)
      Scraper.directory_size(repo_path)
    else
      0
    end
  end

  def sqlite_db_size
    if File.exists?(sqlite_db_path)
      File::Stat.new(sqlite_db_path).size
    else
      0
    end
  end

  def scraperwiki_shortname
    # scraperwiki_url should be of the form https://classic.scraperwiki.com/scrapers/shortname/
    m = scraperwiki_url.match(/https:\/\/classic.scraperwiki.com\/scrapers\/([-\w]+)(\/)?/)
    m[1] if m
  end

  def get_scraperwiki_info
    url = "https://api.scraperwiki.com/api/1.0/scraper/getinfo?format=jsondict&name=#{scraperwiki_shortname}&version=-1&quietfields=runevents%7Chistory%7Cdatasummary%7Cuserroles"
    response = Faraday.get url
    JSON.parse(response.body).first
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
    language = v["language"].to_sym

    # Copy the sqlite database across from Scraperwiki
    url = "https://classic.scraperwiki.com/scrapers/export_sqlite/#{scraperwiki_shortname}/"
    response = Faraday.get(url)
    sqlite_db = response.body
    if sqlite_db =~ /The dataproxy connection timed out, please retry./
      raise response.body
    end
    FileUtils.mkdir_p data_path
    File.open(sqlite_db_path, 'wb') {|file| file.write(sqlite_db) }
    # Rename the main table in the sqlite database
    sql_query_safe("ALTER TABLE swdata RENAME TO #{Scraper.sqlite_table_name}", false)

    # Fill in description
    repo = client.edit_repository(full_name, description: description)
    self.update_attributes(description: description)

    gitignore_contents = "# Ignore output of scraper\n#{Scraper.sqlite_db_filename}\n"
    blobs =  [
      {
        :path => "scraper.#{Scraper.language_to_file_extension(language)}",
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
      blobs << {
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

    # Add another commit (but only if necessary) to translate the code so it runs here
    translated_code = CodeTranslate.translate(language, code)
    unless translated_code == code
      tree2 = client.create_tree(full_name, [
        {
          :path => "scraper.rb",
          :mode => "100644",
          :type => "blob",
          :content => translated_code
        },
      ], :base_tree => tree.sha)
      commit2 = client.create_commit(full_name, "Automatic update to make ScraperWiki scraper work on Morph", tree2.sha, commit.sha)
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
