class ScraperwikiForksController < ApplicationController
  before_filter :authenticate_user!

  def new
    @name_set = !!params[:scraperwiki_shortname]
    @scraper = Scraper.new(scraperwiki_shortname: params[:scraperwiki_shortname])
  end

  # Fork away
  def create
    @scraper = Scraper.new(name: params[:scraper][:name], scraperwiki_shortname: params[:scraper][:scraperwiki_shortname],
      owner_id: params[:scraper][:owner_id], forking: true, forked_by_id: current_user.id)
    # TODO Should we really store full_name in the db?
    @scraper.full_name = "#{@scraper.owner.to_param}/#{@scraper.name}"

    # As quickly as possible check if it's possible to create the repository. If it isn't possible then allow
    # the user to choose another name
    begin
      current_user.octokit_client.repository(@scraper.full_name)
      exists_on_github = true      
    rescue Octokit::NotFound
      exists_on_github = false
    end

    # TODO should really check here that this user has the permissions to write to the owner_id owner
    # It will just get stuck later

    # Should do this with validation
    if !Scraper.exists?(full_name: @scraper.full_name) && !exists_on_github
      if @scraper.save
        ForkScraperwikiWorker.perform_async(@scraper.id)
        #flash[:notice] = "Forking in action..."
        redirect_to @scraper      
      else
        render :new
      end
    else
      @scraper.errors.add(:name, "is already taken")
      render :new
    end
  end
end
