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

    # Should do this with validation
    if Scraper.exists?(name: @scraper.name)
      flash[:alert] = "Name is already taken"
      render :new
      return
    end

    # As quickly as possible check if it's possible to create the repository. If it isn't possible then allow
    # the user to choose another name
    client = Octokit::Client.new :access_token => current_user.access_token
    # We need to set auto_init so that we can create a commit later. The API doesn't support
    # adding a commit to an empty repository
    begin
      repo = client.create_repository(@scraper.name, auto_init: true)
    rescue Octokit::UnprocessableEntity
      flash[:alert] = "Name is already taken"
      # TODO Put the error on the :name field
      render :new
      return
    end
    @scraper.github_id = repo.id
    @scraper.github_url = repo.rels[:html].href
    @scraper.git_url = repo.rels[:git].href
    @scraper.save!

    #repo = client.repository("#{current_user.to_param}/#{@scraper.name}")

    @scraper.delay.copy_code_and_data_from_scraperwiki!
    #flash[:notice] = "Forking in action..."
    redirect_to @scraper
  end
end
