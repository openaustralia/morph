# typed: false
# frozen_string_literal: true

class DocumentationController < ApplicationController
  def api
    # Example scraper
    @scraper = Scraper.find_by(full_name: params[:scraper] || "mlandauer/scraper-blue-mountains") || Scraper.first
    @query = @scraper.database.select_first_ten
  end
end
