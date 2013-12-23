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
    "db/repos/#{full_name}"
  end

  def go
    # TODO If already cloned then just do a pull
    clone_repo
    # TODO Super important high priority: Put this in a docker container
    # TODO Actually run the scraper
    # TODO Run this in the background
    # TODO Capture output to console
    command = "cd #{repo_path}; BUNDLE_GEMFILE=Gemfile rvm . do bundle exec ruby scraper.rb"
    puts "About to run command: #{command}"
    system(command)
  end
end
