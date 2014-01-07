class ScraperwikiForksController < ApplicationController
  before_filter :authenticate_user!

  def new
    @scraper = Scraper.new(name: "scraper-test",
      scraperwiki_url: "https://classic.scraperwiki.com/scrapers/city_of_sydney_development_applications/")
  end

  # Fork away
  def create
    @scraper = Scraper.new(name: params[:scraper][:name], scraperwiki_url: params[:scraper][:scraperwiki_url],
      owner_id: current_user.id, forking: true)
    # TODO Should we really store full_name in the db?
    @scraper.full_name = "#{current_user.to_param}/#{@scraper.name}"

    # As quickly as possible check if it's possible to create the repository. If it isn't possible then allow
    # the user to choose another name
    client = Octokit::Client.new :access_token => current_user.access_token
    begin
      client.repository(@scraper.full_name)
      exists_on_github = true      
    rescue Octokit::NotFound
      exists_on_github = false
    end

    # Should do this with validation
    if !Scraper.exists?(name: @scraper.name) && !exists_on_github
      @scraper.save!
      @scraper.delay.fork_from_scraperwiki!
      #flash[:notice] = "Forking in action..."
      redirect_to @scraper      
    else
      flash[:alert] = "Name is already taken"
      render :new
    end
  end
end
