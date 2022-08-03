# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!, except: :index
  before_action :load_resource, except: %i[index stats]
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

  def watching; end
  def stats; end

  private

  def load_resource
    @user = User.friendly.find(params[:id])
  end
end
