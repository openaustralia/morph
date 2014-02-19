module Morph
  class Github
    def self.synchronise_repo(repo_path, git_url)
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
      # Handle submodules. Always do this
      system("cd #{repo_path}; git submodule init")
      system("cd #{repo_path}; git submodule update")
    end

    # Check if repo name is already in use. This only checks public repos
    def self.in_public_use?(full_name)
      begin
        Octokit.repository(full_name)
        true      
      rescue Octokit::NotFound
        false
      end
    end
  end
end