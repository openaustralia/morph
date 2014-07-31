class ScrapersController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show, :data, :watchers]
  before_filter :load_resource, only: [:settings, :show, :destroy, :update, :run, :stop, :clear,
    :data, :watch, :watchers]

  # All methods
  # :settings, :index, :new, :create, :github, :github_form, :create_github, :scraperwiki,
  # :create_scraperwiki, :show, :destroy, :update, :run, :stop, :clear, :data, :watch, :watchers

  def settings
    authorize! :settings, @scraper
  end

  def index
    @scrapers = Scraper.accessible_by(current_ability).order(:updated_at => :desc).page(params[:page])
  end

  def new
    @scraper = Scraper.new
    authorize! :new, @scraper
  end

  def create
    @scraper = Scraper.new(original_language_key: params[:scraper][:original_language_key],
      owner_id: params[:scraper][:owner_id], name: params[:scraper][:name], description: params[:scraper][:description])
    @scraper.full_name = "#{@scraper.owner.to_param}/#{@scraper.name}"
    authorize! :create, @scraper
    if @scraper.valid?
      @scraper.create_create_scraper_progress!(heading: "New scraper", message: "Queuing", progress: 5)
      @scraper.save
      CreateScraperWorker.perform_async(@scraper.id, current_user.id, scraper_url(@scraper))
      redirect_to @scraper
    else
      render :new
    end
  end

  def github
    authorize! :github, Scraper
    @user = current_user
    @organizations = current_user.organizations
  end

  # For rendering ajax partial in github action
  def github_form
    @scraper = Scraper.new
    render partial: "github_form", locals: {owner: Owner.find(params[:id])}
  end

  def create_github
    @scraper = Scraper.new_from_github(params[:scraper][:full_name], current_user.octokit_client)
    authorize! :create_github, @scraper
    if @scraper.save
      @scraper.create_create_scraper_progress!(heading: "Adding from Github", message: "Queuing", progress: 5)
      @scraper.save
      CreateFromGithubWorker.perform_async(@scraper.id)
      redirect_to @scraper
    else
      render :github
    end
  end

  def scraperwiki
    authorize! :scraperwiki, Scraper
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
    authorize! :show, @scraper

    if !@scraper.exists? && @scraper.can_write?(current_user)
      flash[:error] = "Scraper repo not found - delete and recreate this scraper, or contact us."
      redirect_to settings_scraper_path(@scraper)
    elsif !@scraper.exists?
      raise ActiveRecord::RecordNotFound
    end
  end

  def destroy
    authorize! :destroy, @scraper
    flash[:notice] = "Scraper #{@scraper.name} deleted"
    @scraper.destroy
    # TODO Make this done by default after calling Scraper#destroy
    @scraper.destroy_repo_and_data
    redirect_to @scraper.owner
  end

  def update
    authorize! :update, @scraper
    if @scraper.update_attributes(scraper_params)
      flash[:notice] = "Scraper settings successfully updated"
      sync_update @scraper
      redirect_to @scraper
    else
      render :settings
    end
  end

  def run
    authorize! :run, @scraper
    @scraper.queue!
    @scraper.reload
    sync_update @scraper
    redirect_to @scraper
  end

  def stop
    authorize! :stop, @scraper
    @scraper.stop!
    @scraper.reload
    sync_update @scraper
    redirect_to @scraper
  end

  def clear
    authorize! :clear, @scraper
    @scraper.database.clear
    redirect_to @scraper
  end

  def data
    # Check authentication
    # We're still allowing authentication via header so that old users
    # of the api don't have to change anything
    api_key = request.headers["HTTP_X_API_KEY"] || params[:key]
    if api_key.nil?
      render_error "API key is missing"
      return
    else
      owner = Owner.find_by_api_key(api_key)
      if owner.nil?
        render_error "API key is not valid"
        return
      end
    end

    begin
      respond_to do |format|
        format.sqlite do
          bench = Benchmark.measure do
            send_file @scraper.database.sqlite_db_path, filename: "#{@scraper.name}.sqlite"
          end
          ApiQuery.log!(query: params[:query], scraper: @scraper, owner: owner, benchmark: bench,
            size: @scraper.database.sqlite_db_size, type: "database", format: "sqlite")
        end

        format.json do
          size = nil
          bench = Benchmark.measure do
            result = @scraper.database.sql_query(params[:query])
            # Workaround for https://github.com/rails/rails/issues/15081
            # TODO When the bug above is fixed we should just be able to replace the block below with
            # render :json => result, callback: params[:callback]
            if params[:callback]
              render :json => result, callback: params[:callback], content_type: "application/javascript"
            else
              render :json => result
            end
            size = result.to_json.size
          end
          ApiQuery.log!(query: params[:query], scraper: @scraper, owner: owner, benchmark: bench,
            size: size, type: "sql", format: "json")
        end

        format.csv do
          size = nil
          bench = Benchmark.measure do
            result = @scraper.database.sql_query(params[:query])
            csv_string = CSV.generate do |csv|
              csv << result.first.keys unless result.empty?
              result.each do |row|
                csv << row.values
              end
            end
            send_data csv_string, :filename => "#{@scraper.name}.csv"
            size = csv_string.size
          end
          ApiQuery.log!(query: params[:query], scraper: @scraper, owner: owner, benchmark: bench,
            size: size, type: "sql", format: "csv")
        end

        format.atom do
          size = nil
          bench = Benchmark.measure do
            @result = @scraper.database.sql_query(params[:query])
            render :data
            # TODO Find some more consistent way of measuring size across different formats
            size = @result.to_json.size
          end
          ApiQuery.log!(query: params[:query], scraper: @scraper, owner: owner, benchmark: bench,
            size: size, type: "sql", format: "atom")
        end
      end

    rescue SQLite3::Exception => e
      render_error e.to_s
    end
  end

  # Toggle whether we're watching this scraper
  def watch
    current_user.toggle_watch(@scraper)
    redirect_to :back
  end

  def watchers
    authorize! :watchers, @scraper
  end

  private

  def render_error(message)
    respond_to do |format|
      format.sqlite { render :text => message, status: 401, content_type: :text }
      format.json { render :json => {error: message}, status: 401 }
      format.csv { render text: message, status: 401, content_type: :text }
      format.atom { render :text => message, status: 401, content_type: :text }
    end
  end

  def load_resource
    @scraper = Scraper.friendly.find(params[:id])
  end

  def scraper_params
    params.require(:scraper).permit(:auto_run, variables_attributes: [:id, :name, :value, :_destroy])
  end
end
