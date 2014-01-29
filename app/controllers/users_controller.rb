class UsersController < ApplicationController
  before_filter :authenticate_user!

  def settings
    @user = current_user
  end
end
