class AddDataToContributors < ActiveRecord::Migration
  def change
    Scraper.all.each {|s| s.update_contributors }
  end
end
