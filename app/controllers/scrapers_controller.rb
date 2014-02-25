class ScrapersController < ApplicationController
  before_filter :authenticate_user!, except: [:show, :data]

  def settings
    @scraper = Scraper.find(params[:id])
    unless @scraper.can_write?(current_user)
      redirect_to @scraper
      return
    end
  end

  def new
    @scraper = Scraper.new
  end

  def create
    @scraper = Scraper.new(original_language: params[:scraper][:original_language],
      owner_id: params[:scraper][:owner_id], name: params[:scraper][:name])
    @scraper.full_name = "#{@scraper.owner.to_param}/#{@scraper.name}"
    if !Scraper.can_write?(current_user, @scraper.owner)
      @scraper.errors.add(:owner_id, "doesn't belong to you")
      render :new
    elsif Scraper.exists?(full_name: @scraper.full_name)
      @scraper.errors.add(:name, "is already taken on Morph")
      render :new
    elsif Morph::Github.in_public_use?(@scraper.full_name)
      @scraper.errors.add(:name, "is already taken on GitHub")
      render :new
    else
      repo = Morph::Github.create_repository(current_user, @scraper.owner, @scraper.name)
      # TODO Populate it with a default scraper in the chosen language
      files = {
        Morph::Language.language_to_scraper_filename(@scraper.original_language.to_sym) => Morph::Language.default_scraper(@scraper.original_language.to_sym),
        ".gitignore" => "# Ignore output of scraper\n#{Morph::Database.sqlite_db_filename}\n",
      }
      # TODO Don't use hardcoded urls
      files["README.md"] = "This is a scraper that runs on [Morph](https://morph.io). To get started [see the documentation](https://morph.io/documentation)"
      @scraper.add_commit_to_root_on_github(current_user, files, "Add template for Morph scraper")

      @scraper = Scraper.new_from_github(repo.full_name)
      if @scraper.save        
        # TODO This could be a long running task shouldn't really be in the request cycle
        repo = current_user.octokit_client.edit_repository(@scraper.full_name, homepage: scraper_url(@scraper))
        @scraper.synchronise_repo
        redirect_to @scraper        
      else
        render :new
      end
    end
  end

  def github
  end

  # For rendering ajax partial in github action
  def github_form
    @repos = current_user.github_all_public_repos
    @scraper = Scraper.new
    render partial: "github_form"
  end

  def create_github
    @scraper = Scraper.new_from_github(params[:scraper][:full_name])
    if !@scraper.can_write?(current_user)
      @scraper.errors.add(:full_name, "is not one of your scrapers")
      render :github
    elsif !@scraper.save
      render :github
    else
      # TODO This could be a long running task shouldn't really be in the request cycle
      @scraper.synchronise_repo
      redirect_to @scraper
    end
  end

  def scraperwiki
    @name_set = !!params[:scraperwiki_shortname]
    @scraper = Scraper.new(scraperwiki_shortname: params[:scraperwiki_shortname],
      name: params[:scraperwiki_shortname])
  end

  # Fork away
  def create_scraperwiki
    @scraper = Scraper.new(name: params[:scraper][:name], scraperwiki_shortname: params[:scraper][:scraperwiki_shortname],
      owner_id: params[:scraper][:owner_id], forking: true, forked_by_id: current_user.id)
    # TODO Should we really store full_name in the db?
    @scraper.full_name = "#{@scraper.owner.to_param}/#{@scraper.name}"

    # As quickly as possible check if it's possible to create the repository. If it isn't possible then allow
    # the user to choose another name
    exists_on_github = Morph::Github.in_public_use?(@scraper.full_name)

    # Check that scraperwiki scraper exists
    exists_on_scraperwiki = !!Morph::Scraperwiki.new(@scraper.scraperwiki_shortname).info

    # TODO should really check here that this user has the permissions to write to the owner_id owner
    # It will just get stuck later

    # Should do this with validation
    if !Scraper.exists?(full_name: @scraper.full_name) && !exists_on_github && exists_on_scraperwiki
      if @scraper.save
        ForkScraperwikiWorker.perform_async(@scraper.id)
        #flash[:notice] = "Forking in action..."
        redirect_to @scraper      
      else
        render :scraperwiki
      end
    else
      if !exists_on_scraperwiki
        @scraper.errors.add(:scraperwiki_shortname, "doesn't exist on ScraperWiki")
      end
      if Scraper.exists?(full_name: @scraper.full_name) || exists_on_github
        @scraper.errors.add(:name, "is already taken")
      end
      render :scraperwiki
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
      redirect_to @scraper.owner
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
    query = params[:query] || scraper.database.select_all

    # Check authentication
    api_key = request.headers["HTTP_X_API_KEY"]
    if api_key.nil?
      authenticate_user!
      # TODO Log usage against current_user
    else
      owner = Owner.find_by_api_key(api_key)
      if owner.nil?
        respond_to do |format|
          format.sqlite { render :text => "API key is not valid", status: 401 }
          format.json { render :json => {error: "API key is not valid"}, status: 401 }
          format.csv { render :text => "API key is not valid", status: 401 }
        end            
        return
      end
      # TODO Log usage against owner
    end

    begin
      respond_to do |format|
        format.sqlite { send_file scraper.database.sqlite_db_path, filename: "#{scraper.name}.sqlite" }
        format.json { render :json => scraper.database.sql_query(query) }
        format.csv do
          rows = scraper.database.sql_query(query)
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

  # Toggle whether we're watching this scraper
  def watch
    scraper = Scraper.find(params[:id])
    current_user.toggle_watch(scraper)
    redirect_to :back
  end
end
