class SearchController < ApplicationController
  def search
    @q = params[:q]
    @scrapers = Scraper.search(@q)
    @owners = Owner.search(@q, highlight: {fields: [:nickname, :name, :company, :blog]})
    @type = params[:type]
  end
end
