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

    # Will create a repository. Works for both an individual and an organisation.
    # Returns a repo
    def self.create_repository(user, owner, name)
      if user == owner
        user.octokit_client.create_repository(name, auto_init: true)
      else
        user.octokit_client.create_repository(name, auto_init: true, organization: owner.nickname)
      end
    end

    def self.primary_email(user)
      # TODO If email isn't verified probably should not send email to it
      emails(user).find{|u| u.primary}.email
    end

    # Needs user:email oauth scope for this to work
    # Will return nil if you don't have the right scope
    def self.emails(user)
      begin
        user.octokit_client.emails(accept: 'application/vnd.github.v3')
      rescue Octokit::NotFound
        nil
      end
    end

    # Return a new github access token for a user given their old one. Useful after #heartbleed.
    # No support for this method yet in octokit (it's brand new) so do it ourselves
    def self.reset_authorization(access_token)
      # POST https://api.github.com/applications/:client_id/tokens/:access_token
      client_id = ENV["GITHUB_APP_CLIENT_ID"]
      client_secret = ENV["GITHUB_APP_CLIENT_SECRET"]

      conn = Faraday.new(url: 'https://api.github.com') do |faraday|
        faraday.request :basic_auth, client_id, client_secret
        faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
      end
      res = conn.post("/applications/#{client_id}/tokens/#{access_token}")
      JSON.parse(res.body)["token"]
    end
  end
end
