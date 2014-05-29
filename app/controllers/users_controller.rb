class UsersController < ApplicationController
  before_filter :authenticate_user!, except: :index

  def index
    @users = User.order(created_at: :desc).page(params[:page])
  end

  def settings
    if params[:id]
      @user = User.friendly.find(params[:id])
      if @user != current_user && !current_user.admin?
        render text: "You are not authorised to view this page", status: :unauthorized
        return
      end
    else
      redirect_to user_settings_url(current_user)
    end
  end

  def reset_key
    current_user.set_api_key
    current_user.save!
    redirect_to user_settings_url(current_user)
  end

  def watching
    # Can't do User.find(params[:id]). Figure out why
    @user = Owner.friendly.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @user.user?
  end
end
