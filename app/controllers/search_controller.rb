class SearchController < ApplicationController
  def search
    @q = params[:q]
    @scrapers = Scraper.search(@q)
    @owners = Owner.search(@q)
    @type = params[:type]
  end
end
