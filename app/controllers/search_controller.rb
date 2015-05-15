class SearchController < ApplicationController
  def search
    default_owner_search_params = {highlight: {fields: [:nickname, :name, :company, :blog]}, page: params[:page], per_page: 10}
    default_scraper_search_params = {fields: [{full_name: :word_middle}, :description, {scraped_domain_names: :word_end}], highlight: true, page: params[:page], per_page: 10}

    @q = params[:q]
    @type = params[:type]
    @show = params[:show]

    @owners = Owner.search @q, default_owner_search_params

    all_scrapers = Scraper.search @q, default_scraper_search_params
    @unfiltered_scrapers_count = all_scrapers.total_count

    if @show == "all" && @type != "users"
      @scrapers = all_scrapers
    else
      @scrapers = Scraper.search @q, default_scraper_search_params.merge(where: {has_data?: true})
    end
  end
end
