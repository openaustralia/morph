class OwnersController < ApplicationController
  def show
    @owner = Owner.find(params[:id])
    @scrapers = @owner.scrapers
    @running_scrapers = @scrapers.select{|s| s.running?}
    @erroring_scrapers = @scrapers.select{|s| s.requires_attention?}
    @other_scrapers = @scrapers.select{|s| !s.requires_attention? && !s.running?}
  end

  # Toggle whether we're watching this user / organization
  def watch
    owner = Owner.find(params[:id])
    current_user.toggle_watch(owner)
    redirect_to :back
  end
end
