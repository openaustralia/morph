class UsersController < ApplicationController
  before_filter :authenticate_user!, except: :index

  def index
    @users = User.order(created_at: :desc).page(params[:page])
  end

  def watching
    @user = User.friendly.find(params[:user_id])
  end

  def update
    if current_user.admin?
      @user = User.friendly.find(params[:id])
      @user.update_attributes(buildpacks: params[:user][:buildpacks])
    end
    redirect_to @user
  end
end
