class ScrapersController < ApplicationController
  before_filter :authenticate_user!, except: [:show, :data]
  
  def new
    # Get the list of repositories
    # TODO Move this to an initializer
    Octokit.auto_paginate = true
    @repos = current_user.octokit_client.repositories(nil, sort: :pushed)
    @scraper = Scraper.new
  end

  def create
    # Look up the repository by name
    repo = current_user.octokit_client.repository("#{current_user.to_param}/#{params[:scraper][:name]}")

    # Populate a new scraper with information from the repo
    @scraper = Scraper.new(name: repo.name, full_name: repo.full_name,
      description: repo.description, github_id: repo.id, owner_id: current_user.id,
      github_url: repo.rels[:html].href, git_url: repo.rels[:git].href)
    if @scraper.save
      redirect_to @scraper
    else
      render :new
    end
  end

  def show
    @scraper = Scraper.find(params[:id])
    @rows = @scraper.database.first_ten_rows
  end

  def destroy
    @scraper = Scraper.find(params[:id])
    if @scraper.can_write?(current_user)
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

  def update
    @scraper = Scraper.find(params[:id])
    if @scraper.can_write?(current_user)
      # TODO This is definitely the dumb and long winded way to do things
      if @scraper.update_attributes(auto_run: params[:scraper][:auto_run])
        flash[:notice] = "Scraper settings successfully updated"
      end
    else
      flash[:alert] = "Can't update someone else's scraper"
    end
    redirect_to @scraper
  end

  def run
    scraper = Scraper.find(params[:id])
    if scraper.can_write?(current_user)
      scraper.queue!
    else
      flash[:alert] = "Can't run someone else's scraper!"
    end
    redirect_to scraper
  end

  # TODO Extract checking of who owns the scraper
  def clear
    scraper = Scraper.find(params[:id])
    if scraper.can_write?(current_user)
      scraper.database.clear
    else
      flash[:alert] = "Can't clear someone else's scraper!"
    end
    redirect_to scraper    
  end

  def data
    scraper = Scraper.find(params[:id])
    if params[:format] == "sqlite"
      send_file scraper.database.sqlite_db_path, filename: "#{scraper.name}.sqlite",
        type: "application/x-sqlite3"
    else
      query = params[:query] || Database.select_all
      begin
        rows = scraper.database.sql_query(query)
        respond_to do |format|
          format.json { render :json => rows}
          format.csv do
            csv_string = CSV.generate do |csv|
              csv << rows.first.keys unless rows.empty?
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
