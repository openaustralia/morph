class ScrapersController < ApplicationController
  before_filter :authenticate_user!, except: :show
  
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
    @scraper = Scraper.new(name: repo.name, full_name: repo.full_name,
      description: repo.description, github_id: repo.id, owner_id: current_user.id,
      github_url: repo.rels[:html].href, git_url: repo.rels[:git].href)
    if @scraper.save
      flash[:notice] = "Scraper #{@scraper.name} added"
      redirect_to current_user
    else
      render :new
    end
  end

  def show
    @scraper = Scraper.find(params[:id])
    # Open a db connection
    begin
      db = SQLite3::Database.new("db/scrapers/data/mlandauer/scraper-blue-mountains/scraperwiki.sqlite",
        results_as_hash: true, type_translation: true)
      @rows = db.execute("select * from swdata limit 25")
    rescue SQLite3::CantOpenException
    end
  end

  def destroy
    @scraper = Scraper.find(params[:id])
    if @scraper.owned_by?(current_user)
      flash[:notice] = "Scraper #{@scraper.name} deleted"
      @scraper.destroy
      @scraper.destroy_repo_and_data
      redirect_to current_user
    else
      flash[:alert] = "Can't delete someone else's scraper!"
      redirect_to @scraper
    end
  end

  def run
    scraper = Scraper.find(params[:id])
    if scraper.owned_by?(current_user)
      scraper.go
      flash[:notice] = "Scraper ran"
    else
      flash[:alert] = "Can't run someone else's scraper!"
    end
    redirect_to scraper
  end
end
