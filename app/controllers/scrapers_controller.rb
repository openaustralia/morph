class ScrapersController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show, :data, :watchers]

  def settings
    @scraper = Scraper.friendly.find(params[:id])
    unless @scraper.can_write?(current_user)
      redirect_to @scraper
      return
    end
  end

  def index
    @scrapers = Scraper.order(:updated_at => :desc).page(params[:page])
  end

  def new
    @scraper = Scraper.new
  end

  def create
    @scraper = Scraper.new(original_language: params[:scraper][:original_language],
      owner_id: params[:scraper][:owner_id], name: params[:scraper][:name], description: params[:scraper][:description])
    @scraper.full_name = "#{@scraper.owner.to_param}/#{@scraper.name}"
    if !Scraper.can_write?(current_user, @scraper.owner)
      @scraper.errors.add(:owner_id, "doesn't belong to you")
      render :new
    elsif !@scraper.valid?
      render :new
    else
      @scraper.create_create_scraper_progress!(heading: "New scraper", message: "Queuing", progress: 5)
      @scraper.save
      CreateScraperWorker.perform_async(@scraper.id, current_user.id, scraper_url(@scraper))
      redirect_to @scraper
    end
  end

  def github
  end

  # For rendering ajax partial in github action
  def github_form
    @scraper = Scraper.new
    render partial: "github_form"
  end

  def create_github
    @scraper = Scraper.new_from_github(params[:scraper][:full_name], current_user.octokit_client)
    if !@scraper.can_write?(current_user)
      @scraper.errors.add(:full_name, "is not one of your scrapers")
      render :github
    elsif !@scraper.save
      render :github
    else
      @scraper.create_create_scraper_progress!(heading: "Adding from Github", message: "Queuing", progress: 5)
      @scraper.save
      CreateFromGithubWorker.perform_async(@scraper.id)
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
      owner_id: params[:scraper][:owner_id], forked_by_id: current_user.id)
    # TODO Should we really store full_name in the db?
    @scraper.full_name = "#{@scraper.owner.to_param}/#{@scraper.name}"

    # TODO should really check here that this user has the permissions to write to the owner_id owner
    # It will just get stuck later

    if !@scraper.scraperwiki_shortname
      @scraper.errors.add(:scraperwiki_shortname, 'cannot be blank')
      render :scraperwiki
    elsif @scraper.save
      @scraper.create_create_scraper_progress!(heading: "Forking!", message: "Queuing", progress: 5)
      @scraper.save
      ForkScraperwikiWorker.perform_async(@scraper.id)
      #flash[:notice] = "Forking in action..."
      redirect_to @scraper
    else
      render :scraperwiki
    end
  end

  def show
    @scraper = Scraper.friendly.find(params[:id])
  end

  def destroy
    @scraper = Scraper.friendly.find(params[:id])
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
    @scraper = Scraper.friendly.find(params[:id])
    if @scraper.can_write?(current_user)
      if @scraper.update_attributes(scraper_params)
        flash[:notice] = "Scraper settings successfully updated"
        sync_update @scraper
      else
        render :settings
        return
      end
    else
      flash[:alert] = "Can't update someone else's scraper"
    end
    redirect_to @scraper
  end

  def run
    scraper = Scraper.friendly.find(params[:id])
    if scraper.can_write?(current_user)
      scraper.queue!
      scraper.reload
      sync_update scraper
    else
      flash[:alert] = "Can't run someone else's scraper!"
    end
    redirect_to scraper
  end

  # TODO Extract checking of who owns the scraper
  def clear
    scraper = Scraper.friendly.find(params[:id])
    if scraper.can_write?(current_user)
      scraper.database.clear
    else
      flash[:alert] = "Can't clear someone else's scraper!"
    end
    redirect_to scraper
  end

  def data
    scraper = Scraper.friendly.find(params[:id])

    # Check authentication
    # We're still allowing authentication via header so that old users
    # of the api don't have to change anything
    api_key = request.headers["HTTP_X_API_KEY"] || params[:key]
    if api_key.nil?
      authenticate_user!
      owner = current_user
    else
      owner = Owner.find_by_api_key(api_key)
      if owner.nil?
        respond_to do |format|
          format.sqlite { render :text => "API key is not valid", status: 401 }
          format.json { render :json => {error: "API key is not valid"}, status: 401 }
          format.csv { render :text => "API key is not valid", status: 401 }
          format.atom { render :text => "API key is not valid", status: 401 }
        end
        return
      end
    end

    begin
      respond_to do |format|
        format.sqlite do
          bench = Benchmark.measure do
            send_file scraper.database.sqlite_db_path, filename: "#{scraper.name}.sqlite"
          end
          ApiQuery.log!(query: params[:query], scraper: scraper, owner: owner, benchmark: bench,
            size: scraper.database.sqlite_db_size, type: "database", format: "sqlite")
        end

        format.json do
          size = nil
          bench = Benchmark.measure do
            result = scraper.database.sql_query(params[:query])
            render :json => result, callback: params[:callback]
            size = result.to_json.size
          end
          ApiQuery.log!(query: params[:query], scraper: scraper, owner: owner, benchmark: bench,
            size: size, type: "sql", format: "json")
        end

        format.csv do
          size = nil
          bench = Benchmark.measure do
            result = scraper.database.sql_query(params[:query])
            csv_string = CSV.generate do |csv|
              csv << result.first.keys unless result.empty?
              result.each do |row|
                csv << row.values
              end
            end
            send_data csv_string, :filename => "#{scraper.name}.csv"
            size = csv_string.size
          end
          ApiQuery.log!(query: params[:query], scraper: scraper, owner: owner, benchmark: bench,
            size: size, type: "sql", format: "csv")
        end

        format.atom do
          size = nil
          bench = Benchmark.measure do
            @scraper = scraper
            @result = scraper.database.sql_query(params[:query])
            render :data
            # TODO Find some more consistent way of measuring size across different formats
            size = @result.to_json.size
          end
          ApiQuery.log!(query: params[:query], scraper: scraper, owner: owner, benchmark: bench,
            size: size, type: "sql", format: "atom")
        end
      end

    rescue SQLite3::Exception => e
      respond_to do |format|
        format.json { render :json => {error: e.to_s} }
        format.csv { render :text => "error: #{e}" }
        format.atom { render :text => "error: #{e}" }
      end
    end
  end

  # Toggle whether we're watching this scraper
  def watch
    scraper = Scraper.friendly.find(params[:id])
    current_user.toggle_watch(scraper)
    redirect_to :back
  end

  def watchers
    @scraper = Scraper.friendly.find(params[:id])
  end

  private

  def scraper_params
    params.require(:scraper).permit(:auto_run, variables_attributes: [:id, :name, :value, :_destroy])
  end
end
