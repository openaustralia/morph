class AddOwnerIdToRuns < ActiveRecord::Migration[4.2]
  def change
    add_column :runs, :owner_id, :integer
    Run.connection.execute("UPDATE runs, scrapers SET runs.owner_id = scrapers.owner_id WHERE runs.scraper_id = scrapers.id")
  end
end
