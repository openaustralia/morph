# typed: strict
# frozen_string_literal: true

class UsersController < ApplicationController
  extend T::Sig

  before_action :authenticate_user!, except: :index
  before_action :load_resource, except: %i[index stats]
  load_and_authorize_resource

  sig { void }
  def index
    @users = T.let(@users.order(created_at: :desc), T.untyped)
    respond_to do |format|
      format.html do
        @users = @users.page(params[:page])
      end
      format.json
    end
  end

  sig { void }
  def watching; end

  sig { void }
  def stats; end

  private

  sig { void }
  def load_resource
    @user = T.let(User.friendly.find(params[:id]), T.nilable(User))
  end
end
