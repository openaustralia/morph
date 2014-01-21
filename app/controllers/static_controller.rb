class StaticController < ApplicationController
  def index
  end

  def api
    # Example scraper
    @scraper = Scraper.find_by(full_name: "mlandauer/scraper-blue-mountains") || Scraper.first
    @query = "select * from #{Database.sqlite_table_name} limit 10"
  end
end
