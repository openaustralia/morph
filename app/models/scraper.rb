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

  def destroy_repo
    puts "Destroying git repo #{repo_path}"
    FileUtils::rm_rf repo_path
  end

  def repo_path
    "db/scrapers/repos/#{full_name}"
  end

  def data_path
    "db/scrapers/data/#{full_name}"
  end

  def go
    # TODO If already cloned then just do a pull
    clone_repo
    FileUtils.mkdir_p data_path
    # TODO Super important high priority: Put this in a docker container
    # TODO Actually run the scraper
    # TODO Run this in the background
    # TODO Capture output to console
    # TODO Don't use the Gemfile in the repo
    command = "cd #{data_path}; BUNDLE_GEMFILE=#{Rails.root}/#{repo_path}/Gemfile rvm #{Rails.root}/#{repo_path} do ruby #{Rails.root}/#{repo_path}/scraper.rb"
    puts "About to run command: #{command}"
    system(command)
  end
end
