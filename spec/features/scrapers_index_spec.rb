require 'spec_helper'

describe "scraper exploration" do

  it "tells you how long a scraper has been erroring" do

    @organization = create :organization,
      :nickname => "planningalerts-scrapers"

    VCR.use_cassette('create_valid_scraper', allow_playback_repeats: true) do
      @unique_on_github_1 = create :scraper,
        :owner => @organization,
        :name => "unique_on_github_1",
        :description => "Unique on GitHub 1"
      @unique_on_github_2 = create :scraper,
        :owner => @organization,
        :name => "unique_on_github_2",
        :description => "Unique on GitHub 2"
    end

    @last_run = create :run,
      :scraper => @unique_on_github_1,
      :finished_at => Time.now - (3 * 24 * 60 * 60),
      :status_code => 0
              
    visit "/planningalerts-scrapers"
    within("div#unique_on_github_1") do
      expect(page).to have_content "Errored for 3 days"
    end
    within("div#unique_on_github_2") do
      expect(page).to_not have_content "Errored"
    end
  end

end