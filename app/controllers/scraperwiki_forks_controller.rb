class ScraperwikiForksController < ApplicationController
  before_filter :authenticate_user!

  def new
    @scraper = Scraper.new(name: "scraper-test",
      scraperwiki_url: "https://classic.scraperwiki.com/scrapers/city_of_sydney_development_applications/")
  end

  # Fork away
  def create
    @scraper = Scraper.new(name: params[:scraper][:name], scraperwiki_url: params[:scraper][:scraperwiki_url],
      owner_id: current_user.id)

    url = "https://api.scraperwiki.com/api/1.0/scraper/getinfo?format=jsondict&name=#{@scraper.scraperwiki_shortname}&version=-1&quietfields=runevents%7Chistory%7Cdatasummary%7Cuserroles"
    response = Faraday.get url
    v = JSON.parse(response.body).first
    code = v["code"]
    description = v["title"]
    readme_text = v["description"]

    client = Octokit::Client.new :access_token => current_user.access_token
    # We need to set auto_init so that we can create a commit later. The API doesn't support
    # adding a commit to an empty repository
    repo = client.create_repository(@scraper.name, auto_init: true, description: description)
    #repo = client.repository("#{current_user.to_param}/#{@scraper.name}")

    # TODO Should we really store full_name in the db?
    @scraper.full_name = "#{current_user.to_param}/#{@scraper.name}"
    @scraper.description = description
    @scraper.github_id = repo.id
    @scraper.github_url = repo.rels[:html].href
    @scraper.git_url = repo.rels[:git].href

    # Commit the code
    tree = client.create_tree(repo["full_name"], [
      {
        :path => "scraper.rb",
        :mode => "100644",
        :type => "blob",
        :content => code
      },
      {
        :path => "README.md",
        :mode => "100644",
        :type => "blob",
        :content => readme_text
      },
    ])
    commit_message = "Fork of code from ScraperWiki at #{@scraper.scraperwiki_url}"
    commit = client.create_commit(repo["full_name"], commit_message, tree.sha)
    client.update_ref(repo["full_name"],"heads/master", commit.sha)

    # Now add an extra commit that adds "require 'scraperwiki'" to the top of the scraper code
    # TODO Only do this if necessary
    tree2 = client.create_tree(repo["full_name"], [
      {
        :path => "scraper.rb",
        :mode => "100644",
        :type => "blob",
        :content => "require 'scraperwiki'\n" + code
      },
    ], :base_tree => tree.sha)
    commit2 = client.create_commit(repo["full_name"], "Add require 'scraperwiki'", tree2.sha, commit.sha)
    client.update_ref(repo["full_name"],"heads/master", commit2.sha)

    @scraper.save!
    #flash[:notice] = "Forking in action..."
    redirect_to @scraper

    # TODO Copy across data
    # TODO Make each background step idempotent so that failures can be retried
    # TODO Run all this in the background

    # TODO Check that local scraper with that name doesn't already exist
    # TODO Add repo link
    # TODO Copy across run interval from scraperwiki
    # TODO Handle name on github already taken
    # TODO Check that it's a ruby scraper
    # TODO Add support for non-ruby scrapers
    # TODO Add .gitignore for scraperwiki.sqlite
  end
end
