class ScrapersController < ApplicationController
  before_filter :authenticate_user!
  
  def new
    # Get the list of repositories
    client = Octokit::Client.new :access_token => current_user.access_token
    @repos = client.repositories
    puts @repos.first.to_yaml
    @scraper = Scraper.new
  end
end
