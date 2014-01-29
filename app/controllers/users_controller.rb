class UsersController < ApplicationController
  before_filter :authenticate_user!

  def settings
    @user = current_user
  end

  def reset_key
    current_user.set_api_key
    current_user.save!
    redirect_to :user_settings
  end
end
