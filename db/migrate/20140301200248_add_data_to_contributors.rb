class AddDataToContributors < ActiveRecord::Migration[4.2]
  def change
    Scraper.all.each {|s| s.update_contributors }
  end
end
