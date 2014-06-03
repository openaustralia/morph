class UsersController < ApplicationController
  before_filter :authenticate_user!, except: :index
  before_filter :load_resource, except: :index
  load_and_authorize_resource

  def index
    @users = @users.order(created_at: :desc).page(params[:page])
  end

  def watching
  end

  private

  def load_resource
    @user = User.friendly.find(params[:id])
  end
end
