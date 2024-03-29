# typed: strict
# frozen_string_literal: true

class ScrapersController < ApplicationController
  extend T::Sig

  # Follow what GitHub does here. When you are not authorised to see
  # a scraper it just gives a 404
  rescue_from CanCan::AccessDenied do |_exception|
    raise ActiveRecord::RecordNotFound
  end

  before_action :authenticate_user!, except: %i[
    index show watchers history running
  ]
  before_action :load_resource, only: %i[
    settings show destroy update run stop clear watch
    watchers history toggle_privacy
  ]

  # All methods
  # :settings, :index, :new, :create, :github, :github_form, :create_github,
  # :show, :destroy, :update, :run, :stop,
  # :clear, :watch, :watchers, :history, :running

  sig { void }
  def settings
    authorize! :edit, @scraper
  end

  sig { void }
  def index
    @scrapers = Scraper.accessible_by(current_ability).order(created_at: :desc)
                       .page(params[:page])
  end

  sig { void }
  def new
    @scraper = Scraper.new
    authorize! :new, @scraper
  end

  sig { void }
  def create
    authenticated_user = T.must(current_user)

    scraper = Scraper.new(create_scraper_params)
    scraper.full_name = "#{scraper.owner.to_param}/#{scraper.name}"
    authorize! :create, scraper
    if scraper.valid?
      scraper.create_create_scraper_progress!(
        heading: "New scraper",
        message: "Queuing",
        progress: 5
      )
      scraper.save!
      # Make sure that we add the user as a collaborator immediately so that
      # if the scraper is private they can see it while it is being created.
      # The actual collaborators list will get populated when the repository
      # is synchronised.
      scraper.collaborations.create!(
        owner: current_user,
        admin: true,
        maintain: true,
        pull: true,
        push: true,
        triage: true
      )
      CreateScraperWorker.perform_async(T.must(scraper.id), T.must(authenticated_user.id),
                                        scraper_url(scraper))
      redirect_to scraper
    else
      @scraper = scraper
      render :new
    end
  end

  sig { void }
  def github
    @scraper = Scraper.new
    authorize! :new, @scraper
  end

  # For rendering ajax partial in github action
  sig { void }
  def github_form
    authorize! :new, Scraper
    @scraper = Scraper.new
    owner = Owner.find(params[:id])
    morph_scraper_full_names = owner.scrapers.pluck(:full_name)
    collection = T.must(current_user).github.public_repos(owner.nickname).map do |r|
      exists_on_morph = morph_scraper_full_names.include?(r.full_name)
      description = helpers.radio_description(
        name: r.name,
        description: r.description,
        url: r.rels.html.href,
        exists_on_morph: exists_on_morph
      )

      [description, r.full_name, { disabled: exists_on_morph }]
    end
    render partial: "github_form", locals: { scraper: @scraper, owner: owner, collection: collection }
  end

  sig { void }
  def create_github
    params_scraper = T.cast(params[:scraper], ActionController::Parameters)
    full_name = T.cast(params_scraper[:full_name], String)
    authenticated_user = T.must(current_user)

    scraper = Scraper.new_from_github(full_name, authenticated_user)
    authorize! :create, scraper
    if scraper.save
      scraper.create_create_scraper_progress!(
        heading: "Adding from GitHub",
        message: "Queuing",
        progress: 5
      )
      scraper.save!
      CreateFromGithubWorker.perform_async(T.must(scraper.id))
      redirect_to scraper
    else
      @scraper = scraper
      render :github
    end
  end

  sig { void }
  def show
    authorize! :show, @scraper
  end

  sig { void }
  def destroy
    scraper = T.must(@scraper)

    authorize! :destroy, scraper
    flash[:notice] = "Scraper #{scraper.name} deleted"
    scraper.destroy
    # TODO: Make this done by default after calling Scraper#destroy
    scraper.destroy_repo_and_data
    redirect_to scraper.owner
  end

  sig { void }
  def update
    scraper = T.must(@scraper)

    authorize! :update, scraper
    if scraper.update(scraper_params)
      sync_update scraper
      redirect_to scraper, notice: t(".success")
    else
      render :settings
    end
  end

  sig { void }
  def run
    scraper = T.must(@scraper)

    authorize! :update, scraper
    scraper.queue!
    scraper.reload
    sync_update scraper
    redirect_to scraper
  end

  sig { void }
  def stop
    scraper = T.must(@scraper)

    authorize! :update, scraper
    scraper.stop!
    scraper.reload
    sync_update scraper
    redirect_to scraper
  end

  sig { void }
  def clear
    scraper = T.must(@scraper)

    authorize! :destroy, scraper
    scraper.database.clear
    scraper.reindex
    redirect_to scraper
  end

  # Toggle whether we're watching this scraper
  sig { void }
  def watch
    authorize! :watch, @scraper
    scraper = T.must(@scraper)
    authenticated_user = T.must(current_user)

    authenticated_user.toggle_watch(scraper)
    redirect_back(fallback_location: root_path)
  end

  sig { void }
  def watchers
    authorize! :show, @scraper
  end

  sig { void }
  def history
    authorize! :show, @scraper
  end

  sig { void }
  def running
    authorize! :index, Scraper
    # TODO: Can't use Scraper.accessible_by(current_ability) because "running" below is not acting as a scope. Would be great to fix this.
    # So, we're doing this slightly ugly work around of checking each scraper in turn whether it can be seen by the user
    @scrapers = T.let(Scraper.running.select { |s| can?(:show, s) }, T.nilable(T::Array[Scraper]))
  end

  sig { void }
  def toggle_privacy
    # TODO: Rename create_private to something more sensible
    authorize! :create_private, @scraper
    scraper = T.must(@scraper)
    new_privacy = !scraper.private
    scraper.transaction do
      scraper.update!(private: new_privacy)
      T.must(current_user).github.update_privacy(scraper.full_name, new_privacy)
    end
    redirect_to @scraper, notice: "#{scraper.full_name} is now #{helpers.privacy_in_words(scraper.private)} on morph.io"
  end

  private

  # Overriding the default ability class name used because we've split them out. See
  # https://github.com/CanCanCommunity/cancancan/blob/develop/docs/split_ability.md
  sig { returns(Ability) }
  def current_ability
    @current_ability ||= T.let(ScraperAbility.new(current_user), T.nilable(ScraperAbility))
  end

  sig { void }
  def load_resource
    @scraper = T.let(Scraper.friendly.find(params[:id]), T.nilable(Scraper))
  end

  sig { returns(ActionController::Parameters) }
  def scraper_params
    s = T.cast(params.require(:scraper), ActionController::Parameters)
    permitted_attributes = [:auto_run]
    permitted_attributes << :memory_mb if can? :memory_setting, @scraper
    s.permit(*permitted_attributes,
             variables_attributes: %i[
               id name value _destroy
             ],
             webhooks_attributes: %i[
               id url _destroy
             ])
  end

  sig { returns(ActionController::Parameters) }
  def create_scraper_params
    s = T.cast(params.require(:scraper), ActionController::Parameters)
    permitted_attributes = %i[original_language_key owner_id name description]
    permitted_attributes << :private if can? :create_private, Scraper
    s.permit(*permitted_attributes)
  end
end
