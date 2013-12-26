class Scraper < ActiveRecord::Base
  belongs_to :owner, class_name: User

  extend FriendlyId
  friendly_id :full_name, use: :finders

  def owned_by?(user)
    owner == user
  end

  def clone_repo
    puts "Cloning git repo #{git_url}"
    gritty = Grit::Git.new(repo_path)
    gritty.clone({:verbose => true, :progress => true}, git_url, repo_path)
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
    # TODO On Linux we'll have access to the "docker" command line which can show standard out which
    # would be very helpful. As far as I can tell this is not currently possible with the docker api gem.

    # TODO Move these Docker setup bits to an initializer
    Docker.validate_version!
    # Set read timeout to a silly 30 minutes (we'll need a bit of time to build an image)
    Docker.options[:read_timeout] = 1800

    puts "Building docker image (this is likely to take a while)..."
    image = Docker::Image.build_from_dir("lib/build_docker_image") {|c| puts c}
    image.tag(repo: docker_image_name, force: true)
  end

  def go
    # TODO If already cloned then just do a pull
    clone_repo
    FileUtils.mkdir_p data_path
    c = Docker::Container.create("Cmd" => ['/bin/bash','-l','-c','ruby /repo/scraper.rb'], "Image" => Scraper.docker_image_name)
    # TODO the local path will be different if docker isn't running through Vagrant (i.e. locally)
    local_root_path = "/vagrant"
    # TODO Run this in the background
    # TODO Capture output to console
    c.start("Binds" => [
      "#{local_root_path}/#{repo_path}:/repo",
      "#{local_root_path}/#{data_path}:/data"
    ])
    puts "Running docker container..."
    p c.attach(stream: true, stdout: true, stderr: true, logs: true) {|s,c| puts c}
  end

  def sql_query(query)
    db = SQLite3::Database.new("#{data_path}/scraperwiki.sqlite",
      results_as_hash: true, type_translation: true)
    db.execute(query)
  end

  def sql_query_safe(query)
    begin
      sql_query(query)
    rescue SQLite3::CantOpenException, SQLite3::SQLException
      nil
    end
  end  
end
