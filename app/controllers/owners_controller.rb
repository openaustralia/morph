class OwnersController < ApplicationController
  def show
    @owner = Owner.find(params[:id])
    @scrapers = @owner.scrapers

    # Split out scrapers into different groups
    @running_scrapers, @erroring_scrapers, @other_scrapers = [], [], []
    @scrapers.each do |scraper|
      if scraper.running?
        @running_scrapers << scraper
      elsif scraper.requires_attention?
        @erroring_scrapers << scraper
      else
        @other_scrapers << scraper
      end
    end
  end

  # Toggle whether we're watching this user / organization
  def watch
    owner = Owner.find(params[:id])
    current_user.toggle_watch(owner)
    redirect_to :back
  end
end
