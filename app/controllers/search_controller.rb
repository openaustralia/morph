class SearchController < ApplicationController
  def search
    @q = params[:q]
    @scrapers = Scraper.search @q, highlight: {fields: [:full_name, :description, :scraped_domain_names]}, page: params[:page], per_page: 10
    @owners = Owner.search @q, highlight: {fields: [:nickname, :name, :company, :blog]}, page: params[:page], per_page: 10
    @type = params[:type]
  end
end
