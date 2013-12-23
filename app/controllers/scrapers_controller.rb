class ScrapersController < ApplicationController
  before_filter :authenticate_user!
  
  def new
    # Get the list of repositories
    # TODO Move this to an initializer
    Octokit.auto_paginate = true
    client = Octokit::Client.new :access_token => current_user.access_token
    @repos = client.repositories
    puts @repos.first.to_yaml
    @scraper = Scraper.new
  end

  def create
    # Get the rest of the info from the API
    client = Octokit::Client.new :access_token => current_user.access_token

    # Look up the repository by name
    repo = client.repository("#{current_user.to_param}/#{params[:scraper][:name]}")

    # Populate a new scraper with information from the repo
    @scraper = Scraper.new(name: repo.name, description: repo.description, github_id: repo.id, owner_id: current_user.id)
    if @scraper.save
      flash[:notice] = "Scraper #{@scraper.name} added"
      redirect_to current_user
    else
      render :new
    end
  end
end
