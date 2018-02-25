class ScrapersController < ApplicationController
  before_filter :authenticate_user!, except: [
    :index, :show, :data, :watchers, :history
  ]
  before_filter :load_resource, only: [
    :settings, :show, :destroy, :update, :run, :stop, :clear, :data, :watch,
    :watchers, :history
  ]

  # All methods
  # :settings, :index, :new, :create, :github, :github_form, :create_github,
  # :scraperwiki, :create_scraperwiki, :show, :destroy, :update, :run, :stop,
  # :clear, :data, :watch, :watchers

  def settings
    authorize! :settings, @scraper
  end

  def index
    @scrapers = Scraper.accessible_by(current_ability).order(created_at: :desc)
                .page(params[:page])
  end

  def new
    @scraper = Scraper.new
    authorize! :new, @scraper
  end

  def create
    @scraper = Scraper.new(
      original_language_key: params[:scraper][:original_language_key],
      owner_id: params[:scraper][:owner_id],
      name: params[:scraper][:name],
      description: params[:scraper][:description]
    )
    @scraper.full_name = "#{@scraper.owner.to_param}/#{@scraper.name}"
    authorize! :create, @scraper
    if @scraper.valid?
      @scraper.create_create_scraper_progress!(
        heading: 'New scraper',
        message: 'Queuing',
        progress: 5
      )
      @scraper.save
      CreateScraperWorker.perform_async(@scraper.id, current_user.id,
                                        scraper_url(@scraper))
      redirect_to @scraper
    else
      render :new
    end
  end

  def github
    authorize! :github, Scraper
  end

  # For rendering ajax partial in github action
  def github_form
    @scraper = Scraper.new
    render partial: 'github_form', locals: { owner: Owner.find(params[:id]) }
  end

  def create_github
    @scraper = Scraper.new_from_github(params[:scraper][:full_name],
                                       current_user.octokit_client)
    authorize! :create_github, @scraper
    if @scraper.save
      @scraper.create_create_scraper_progress!(
        heading: 'Adding from GitHub',
        message: 'Queuing',
        progress: 5
      )
      @scraper.save
      CreateFromGithubWorker.perform_async(@scraper.id)
      redirect_to @scraper
    else
      render :github
    end
  end

  def scraperwiki
    authorize! :scraperwiki, Scraper
    if params[:scraperwiki_shortname].nil?
      render text: "scraperwiki_shortname needs to be set. This should happen automatically when migrating to morph.io from ScraperWiki Classic", status: :bad_request
      return
    end
    @scraper = Scraper.new(
      scraperwiki_shortname: params[:scraperwiki_shortname],
      name: params[:scraperwiki_shortname]
    )
  end

  # Fork away
  def create_scraperwiki
    @scraper = Scraper.new(
      name: params[:scraper][:name],
      scraperwiki_shortname: params[:scraper][:scraperwiki_shortname],
      owner_id: params[:scraper][:owner_id],
      forked_by_id: current_user.id
    )
    # TODO: Should we really store full_name in the db?
    @scraper.full_name = "#{@scraper.owner.to_param}/#{@scraper.name}"

    # TODO: should really check here that this user has the permissions to
    # write to the owner_id owner
    # It will just get stuck later

    if !@scraper.scraperwiki_shortname
      @scraper.errors.add(:scraperwiki_shortname, 'cannot be blank')
      render :scraperwiki
    elsif @scraper.save
      @scraper.create_create_scraper_progress!(
        heading: 'Forking!',
        message: 'Queuing',
        progress: 5
      )
      @scraper.save
      ForkScraperwikiWorker.perform_async(@scraper.id)
      # flash[:notice] = 'Forking in action...'
      redirect_to @scraper
    else
      render :scraperwiki
    end
  end

  def show
    authorize! :show, @scraper
  end

  def destroy
    authorize! :destroy, @scraper
    flash[:notice] = "Scraper #{@scraper.name} deleted"
    @scraper.destroy
    # TODO: Make this done by default after calling Scraper#destroy
    @scraper.destroy_repo_and_data
    redirect_to @scraper.owner
  end

  def update
    authorize! :update, @scraper
    if @scraper.update_attributes(scraper_params)
      flash[:notice] = 'Scraper settings successfully updated'
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
    @scraper.reindex
    redirect_to @scraper
  end

  def data
    # Check authentication
    # We're still allowing authentication via header so that old users
    # of the api don't have to change anything
    api_key = request.headers['HTTP_X_API_KEY'] || params[:key]
    if api_key.nil?
      render_error 'API key is missing'
      return
    else
      owner = Owner.find_by_api_key(api_key)
      if owner.nil?
        render_error 'API key is not valid'
        return
      end
    end

    begin
      respond_to do |format|
        format.sqlite { data_sqlite(owner) }
        format.json   { data_json(owner)   }
        format.csv    { data_csv(owner)    }
        format.atom   { data_atom(owner)   }
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

  def history
  end

  def running
    @scrapers = Scraper.running
  end

  private

  def data_sqlite(owner)
    bench = Benchmark.measure do
      send_file @scraper.database.sqlite_db_path,
                filename: "#{@scraper.name}.sqlite"
    end
    ApiQuery.log!(
      query: params[:query],
      scraper: @scraper,
      owner: owner,
      benchmark: bench,
      size: @scraper.database.sqlite_db_size,
      type: 'database',
      format: 'sqlite'
    )
  end

  # This can load the entire sqlite database into memory. Eek!
  # TODO: Fix this
  def data_json(owner)
    size = nil
    bench = Benchmark.measure do
      result = @scraper.database.sql_query(params[:query])
      # Workaround for https://github.com/rails/rails/issues/15081
      # TODO: When the bug above is fixed we should just be able to
      # replace the block below with
      # render :json => result, callback: params[:callback]
      # By the looks of it this bug is fixed in rails 4.2.x
      if params[:callback]
        render json: result, callback: params[:callback],
               content_type: 'application/javascript'
      else
        render json: result
      end
      size = result.to_json.size
    end
    ApiQuery.log!(
      query: params[:query],
      scraper: @scraper,
      owner: owner,
      benchmark: bench,
      size: size,
      type: 'sql',
      format: 'json'
    )
  end

  def data_csv(owner)
    size = 0
    bench = Benchmark.measure do
      headers["Content-Disposition"] = "attachment; filename=#{@scraper.name}.csv"
      self.response_body = Enumerator.new do |lines|
        displayed_header = false
        @scraper.database.sql_query_streaming(params[:query]) do |row|
          # only show the header once at the beginning
          unless displayed_header
            s = row.keys.to_csv
            size += s.size
            lines << s
            displayed_header = true
          end
          s = row.values.to_csv
          size += s.size
          lines << s
        end
      end
    end
    ApiQuery.log!(
      query: params[:query],
      scraper: @scraper,
      owner: owner,
      benchmark: bench,
      size: size,
      type: 'sql',
      format: 'csv'
    )
  end

  # This can load the entire sqlite database into memory. Eek!
  # TODO: Fix this
  def data_atom(owner)
    size = nil
    bench = Benchmark.measure do
      @result = @scraper.database.sql_query(params[:query])
      render :data
      # TODO: Find some more consistent way of measuring size across
      # different formats
      size = @result.to_json.size
    end
    ApiQuery.log!(
      query: params[:query],
      scraper: @scraper,
      owner: owner,
      benchmark: bench,
      size: size,
      type: 'sql',
      format: 'atom'
    )
  end

  def render_error(message)
    respond_to do |format|
      format.sqlite { render text: message, status: 401, content_type: :text }
      format.json { render json: { error: message }, status: 401 }
      format.csv { render text: message, status: 401, content_type: :text }
      format.atom { render text: message, status: 401, content_type: :text }
    end
  end

  def load_resource
    @scraper = Scraper.friendly.find(params[:id])
  end

  def scraper_params
    params.require(:scraper).permit(:auto_run, variables_attributes: [
      :id, :name, :value, :_destroy], webhooks_attributes: [
      :id, :url, :_destroy])
  end
end
