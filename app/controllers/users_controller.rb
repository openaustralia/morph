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
    # TODO In future we will allow admins to reset other people's keys
    # That's why we're doing this in this slightly roundabout way
    @user = User.friendly.find(params[:id])
    if @user == current_user
      @user.set_api_key
      @user.save!
    end
    redirect_to user_settings_url(current_user)
  end

  def watching
    @user = User.friendly.find(params[:id])
  end

  def update
    if current_user.admin?
      @user = User.friendly.find(params[:id])
      @user.update_attributes(buildpacks: params[:user][:buildpacks])
    end
    redirect_to @user
  end
end
