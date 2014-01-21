class StaticController < ApplicationController
  def index
  end

  def api
    # Example scraper
    @scraper = Scraper.find_by(full_name: "mlandauer/scraper-blue-mountains") || Scraper.first
    @query = Database.select_first_ten
  end
end
