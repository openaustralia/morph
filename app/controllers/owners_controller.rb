class OwnersController < ApplicationController
  def show
    @owner = Owner.find(params[:id])
  end

  # Toggle whether we're watching this user / organization
  def watch
    owner = Owner.find(params[:id])
    current_user.toggle_watch(owner)
    redirect_to owner
  end
end
