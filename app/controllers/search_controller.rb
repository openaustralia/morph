class SearchController < ApplicationController
  def search
    @q = params[:q]
    @scrapers = Scraper.search(@q, highlight: {fields: [:full_name, :description]})
    @owners = Owner.search(@q, highlight: {fields: [:nickname, :name, :company, :blog]})
    @type = params[:type]
  end
end
