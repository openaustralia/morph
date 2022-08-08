# typed: true
# frozen_string_literal: true

class SearchController < ApplicationController
  def search
    default_owner_search_params = { highlight: { fields: %i[nickname name company blog] }, page: params[:page], per_page: 10 }
    default_scraper_search_params = { fields: [{ full_name: :word_middle }, :description, { scraped_domain_names: :word_end }], highlight: true, page: params[:page], per_page: 10 }

    @q = params[:q]
    @type = params[:type]
    @show = params[:show]

    @owners = Owner.search @q, default_owner_search_params
    @all_scrapers = Scraper.search @q, default_scraper_search_params
    @filtered_scrapers = Scraper.search @q, default_scraper_search_params.merge(where: { data?: true })

    @scrapers = @show == "all" ? @all_scrapers : @filtered_scrapers
  end
end
