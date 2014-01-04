class ScraperwikiForksController < ApplicationController
  def new
    @scraper = Scraper.new
  end
end
