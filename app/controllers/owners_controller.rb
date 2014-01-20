class OwnersController < ApplicationController
  def show
    @owner = Owner.find(params[:id])
  end
end
