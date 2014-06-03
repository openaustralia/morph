class OwnersController < ApplicationController
  def show
    @owner = Owner.friendly.find(params[:id])
    authorize! :show, @owner
    @scrapers = @owner.scrapers.includes(:last_run => :log_lines)

    # Split out scrapers into different groups
    @running_scrapers, @erroring_scrapers, @other_scrapers = [], [], []
    @scrapers.each do |scraper|
      if scraper.running?
        @running_scrapers << scraper
      elsif scraper.requires_attention?
        @erroring_scrapers << scraper
      else
        @other_scrapers << scraper
      end
    end
  end

  def settings_redirect
    redirect_to settings_owner_url(current_user)
  end

  def settings
    @owner = Owner.friendly.find(params[:id])
    authorize! :settings, @owner
  end

  def update
    @owner = Owner.friendly.find(params[:id])
    authorize! :update, @owner
    if @owner.user?
      @owner.update_attributes(buildpacks: params[:user][:buildpacks])
    elsif @owner.organization?
      @owner.update_attributes(buildpacks: params[:organization][:buildpacks])
    else
      raise "Hmm?"
    end
    redirect_to owner
  end

  def reset_key
    # TODO In future we will allow admins to reset other people's keys
    # That's why we're doing this in this slightly roundabout way
    @owner = Owner.friendly.find(params[:id])
    authorize :reset_key, @owner
    @owner.set_api_key
    @owner.save!
    redirect_to settings_owner_url(@owner)
  end

  # Toggle whether we're watching this user / organization
  def watch
    @owner = Owner.friendly.find(params[:id])
    authorize! :watch, @owner
    current_user.toggle_watch(@owner)
    redirect_to :back
  end
end
