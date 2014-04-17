class DocumentationController < ApplicationController
  def index
  end

  def api
    # Example scraper
    @scraper = Scraper.find_by(full_name: params[:scraper] || "mlandauer/scraper-blue-mountains") || Scraper.first
    @query = @scraper.database.select_first_ten
  end

  def pricing
    render layout: "application"
  end

  def what_is_new
  end
end
