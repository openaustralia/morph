require 'spec_helper'

describe "scraper exploration" do

  it "tells you how long a scraper has been erroring" do

    @organization = create :organization,
      :nickname => "planningalerts-scrapers"

    VCR.use_cassette('create_valid_scraper', allow_playback_repeats: true) do
      @unique_on_github_1 = create :scraper,
        :owner => @organization,
        :name => "unique_on_github_1",
        :description => "Unique on GitHub 1",
        :auto_run => true
      @unique_on_github_2 = create :scraper,
        :owner => @organization,
        :name => "unique_on_github_2",
        :description => "Unique on GitHub 2",
        :auto_run => true
      @unique_on_github_3 = create :scraper,
        :owner => @organization,
        :name => "unique_on_github_3",
        :description => "Unique on GitHub 3",
        :auto_run => true
    end

    @first_run_for_scraper_1 = create :run,
      :scraper => @unique_on_github_1,
      :finished_at => Time.now - 230000,      
      :queued_at => Time.now - 210000,
      :status_code => 0
              
    @last_run_for_scraper_1 = create :run,
      :scraper => @unique_on_github_1,
      :finished_at => Time.now - 3000,
      :queued_at => Time.now - 1000,
      :status_code => 1
              
    @last_run_for_scraper_3 = create :run,
      :scraper => @unique_on_github_3,
      :finished_at => Time.now - 3000,
      :queued_at => Time.now - 1000,
      :status_code => 0

    visit "/planningalerts-scrapers"
    save_and_open_page
    within("div.scraper-alerts-list") do
      within("div#unique_on_github_1") do
        expect(page).to have_content "Errored for 3 days"
      end
      within("div#unique_on_github_2") do
        expect(page).to have_content "Never run successfully"
      end
      within("div#unique_on_github_3") do
        expect(page).to_not have_content "Errored for"
        expect(page).to_not have_content "Never run successfully"  
      end
    end
  end

end