class UsersController < ApplicationController
  before_filter :authenticate_user!

  def index
    @users = User.order(created_at: :desc).page(params[:page])
  end

  def settings
    @user = current_user
  end

  def reset_key
    current_user.set_api_key
    current_user.save!
    redirect_to :user_settings
  end

  def watching
    # Can't do User.find(params[:id]). Figure out why
    @user = Owner.friendly.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @user.user?
  end
end
