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
    # We need to set auto_init so that we can create a commit later. The API doesn't support
    # adding a commit to an empty repository
    #repo = client.create_repository(@scraper.name, auto_init: true)
    repo = client.repository("#{current_user.to_param}/#{@scraper.name}")
    # TODO Copy across source code (with comment for commit with link back to scraperwiki)
    puts "scraperwiki shortname: #{@scraper.scraperwiki_shortname}" 
    url = "https://api.scraperwiki.com/api/1.0/scraper/getinfo?format=jsondict&name=#{@scraper.scraperwiki_shortname}&version=-1&quietfields=runevents%7Chistory%7Cdatasummary%7Cuserroles"
    response = Faraday.get url
    code = (JSON.parse(response.body).first)["code"]
    puts code
    # Create blob
    puts "Creating blob..."
    blob_sha = client.create_blob(repo["full_name"], code)

    tree = client.create_tree(repo["full_name"], [ {
      :path => "scraper.rb",
      :mode => "100644",
      :type => "blob",
      # TODO Could use :content instead of :sha - more concise
      :sha => blob_sha
    } ], :base_tree => "")

    puts "Return from create_tree:"
    p tree
    commit = client.create_commit(repo["full_name"], "Fork from Scraperwiki", tree.sha)
    p commit
    # Now set update the master branch
    client.update_ref(repo["full_name"],"heads/master", commit.sha)
    flash[:notice] = "Forking in action..."
    redirect_to new_scraperwiki_fork_url
    # TODO Check that it's a ruby scraper
    # TODO Add support for non-ruby scrapers
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
