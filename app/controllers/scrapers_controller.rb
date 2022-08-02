# frozen_string_literal: true

class ScrapersController < ApplicationController
  before_action :authenticate_user!, except: %i[
    index show data watchers history
  ]
  before_action :load_resource, only: %i[
    settings show destroy update run stop clear data watch
    watchers history
  ]

  # All methods
  # :settings, :index, :new, :create, :github, :github_form, :create_github,
  # :show, :destroy, :update, :run, :stop,
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
        heading: "New scraper",
        message: "Queuing",
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
    render partial: "github_form", locals: { owner: Owner.find(params[:id]) }
  end

  def create_github
    @scraper = Scraper.new_from_github(params[:scraper][:full_name],
                                       current_user.octokit_client)
    authorize! :create_github, @scraper
    if @scraper.save
      @scraper.create_create_scraper_progress!(
        heading: "Adding from GitHub",
        message: "Queuing",
        progress: 5
      )
      @scraper.save
      CreateFromGithubWorker.perform_async(@scraper.id)
      redirect_to @scraper
    else
      render :github
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
    if @scraper.update(scraper_params)
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
    @scraper.reindex
    redirect_to @scraper
  end

  # Toggle whether we're watching this scraper
  def watch
    current_user.toggle_watch(@scraper)
    redirect_back(fallback_location: root_path)
  end

  def watchers
    authorize! :watchers, @scraper
  end

  def history; end

  def running
    @scrapers = Scraper.running
  end

  private

  def load_resource
    @scraper = Scraper.friendly.find(params[:id])
  end

  def scraper_params
    a = if can? :memory_setting, @scraper
          %i[auto_run memory_mb]
        else
          [:auto_run]
        end
    params.require(:scraper).permit(*a, variables_attributes: %i[
                                      id name value _destroy
                                    ], webhooks_attributes: %i[
                                      id url _destroy
                                    ])
  end
end
