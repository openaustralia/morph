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
end
