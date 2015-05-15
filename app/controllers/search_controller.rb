class SearchController < ApplicationController
  def search
    @q = params[:q]
    @owners = Owner.search @q, highlight: {fields: [:nickname, :name, :company, :blog]}, page: params[:page], per_page: 10
    @type = params[:type]
    @show = params[:show]

    all_scrapers = Scraper.search @q, fields: [{full_name: :word_middle}, :description, {scraped_domain_names: :word_end}], highlight: true, page: params[:page], per_page: 10
    @scrapers_total_count = all_scrapers.total_count

    if @show == "all" && @type != "users"
      @scrapers = Scraper.search @q, fields: [{full_name: :word_middle}, :description, {scraped_domain_names: :word_end}], highlight: true, page: params[:page], per_page: 10
    else
      @scrapers = Scraper.search @q, where: {has_data?: true}, fields: [{full_name: :word_middle}, :description, {scraped_domain_names: :word_end}], highlight: true, page: params[:page], per_page: 10
    end
  end
end
