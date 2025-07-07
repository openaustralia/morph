class AddCreateScraperProgressIdToScrapers < ActiveRecord::Migration[4.2]
  def change
    add_column :scrapers, :create_scraper_progress_id, :integer
  end
end
