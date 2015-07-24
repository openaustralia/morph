class UsersController < ApplicationController
  before_filter :authenticate_user!, except: :index
  before_filter :load_resource, except: [:index, :stats]
  load_and_authorize_resource

  def index
    @users = @users.order(created_at: :desc)
    respond_to do |format|
      format.html do
        @users = @users.page(params[:page])
      end
      format.json
    end
  end

  def watching
  end

  private

  def load_resource
    @user = User.friendly.find(params[:id])
  end
end
