class OwnersController < ApplicationController
  before_filter :authenticate_user!, except: :show
  before_filter :load_resource, except: :settings_redirect
  authorize_resource
  skip_authorize_resource only: :settings_redirect

  def show
    @scrapers = @owner.scrapers.includes(:last_run)

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
  end

  def update
    if @owner.user?
      @owner.update_attributes(
        see_downloads: params[:user][:see_downloads],
        see_support_levels: params[:user][:see_support_levels])
    end
    redirect_to @owner
  end

  def reset_key
    @owner.set_api_key
    @owner.save!
    redirect_to settings_owner_url(@owner)
  end

  # Toggle whether we're watching this user / organization
  def watch
    current_user.toggle_watch(@owner)
    redirect_to :back
  end

  private

  def load_resource
    @owner = Owner.friendly.find(params[:id])
  end
end
