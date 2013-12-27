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
      redirect_to @scraper
    else
      render :new
    end
  end

  def show
    @scraper = Scraper.find(params[:id])
    @rows = @scraper.sql_query_safe("select * from swdata limit 10")
  end

  def destroy
    @scraper = Scraper.find(params[:id])
    if @scraper.owned_by?(current_user)
      flash[:notice] = "Scraper #{@scraper.name} deleted"
      @scraper.destroy
      # TODO Make this done by default after calling Scraper#destroy
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
    else
      flash[:alert] = "Can't run someone else's scraper!"
    end
    redirect_to scraper
  end

  def data
    scraper = Scraper.find(params[:id])
    if params[:format] == "sqlite"
      send_file scraper.sqlite_db_path, filename: "#{scraper.name}.sqlite",
        type: "application/x-sqlite3"
    else
      query = params[:query] || "select * from swdata"
      begin
        rows = scraper.sql_query(query)
        respond_to do |format|
          format.json { render :json => rows}
          format.csv do
            csv_string = CSV.generate do |csv|
              csv << rows.first.keys
              rows.each do |row|
                csv << row.values
              end
            end
            send_data csv_string, :filename => "#{scraper.name}.csv"
          end
        end
      rescue SQLite3::Exception => e
        respond_to do |format|
          format.json { render :json => {error: e.to_s} }
          format.csv { send_data "error: #{e}", :filename => "#{scraper.name}.csv" }
        end
      end
    end
  end
end
