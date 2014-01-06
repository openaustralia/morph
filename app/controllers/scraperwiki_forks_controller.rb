class ScraperwikiForksController < ApplicationController
  before_filter :authenticate_user!

  def new
    @scraper = Scraper.new(name: "scraper-test",
      scraperwiki_url: "https://classic.scraperwiki.com/scrapers/city_of_sydney_development_applications/")
  end

  # Fork away
  def create
    @scraper = Scraper.new(name: params[:scraper][:name], scraperwiki_url: params[:scraper][:scraperwiki_url])
    # First off create the repo on GitHub
    client = Octokit::Client.new :access_token => current_user.access_token
    client.create_repository(@scraper.name)
    # TODO Copy across source code (with comment for commit with link back to scraperwiki)
    # TODO Handle name on github already taken
    # TODO Copy across data
    # TODO Add repo description
    # TODO Add repo link
    # TODO Add require scraperwiki to code (if required)
    # TODO Setup scraper here
    # TODO Copy across run interval from scraperwiki
    # TODO Run all this in the background
    # TODO Make each background step idempotent so that failures can be retried
  end
end
