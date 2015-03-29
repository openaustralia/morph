class StaticController < ApplicationController
  def index
  end

  def search
    @q = params[:q]
  end
end
