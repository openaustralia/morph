class SearchController < ApplicationController
  def search
    @q = params[:q]
    @scrapers = Scraper.search @q, fields: [{full_name: :word_middle}, :description, {scraped_domain_names: :word_end}], highlight: true, page: params[:page], per_page: 10
    @owners = Owner.search @q, highlight: {fields: [:nickname, :name, :company, :blog]}, page: params[:page], per_page: 10
    @type = params[:type]
    @show = params[:show]
  end
end
