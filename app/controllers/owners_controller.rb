class OwnersController < ApplicationController
  before_filter :authenticate_user!, except: :show
  before_filter :load_resource, except: :settings_redirect
  authorize_resource
  skip_authorize_resource only: :settings_redirect

  def show
    # Whether this user has just become a supporter
    @new_supporter = session[:new_supporter]
    # Only do this once
    session[:new_supporter] = false if @new_supporter

    @scrapers = @owner.scrapers.order(:updated_at).includes(:last_run)

  end

  def settings_redirect
    redirect_to settings_owner_url(current_user)
  end

  def settings
  end

  def update
    if @owner.user?
      @owner.update_attributes(
        see_downloads: params[:user][:see_downloads])
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
