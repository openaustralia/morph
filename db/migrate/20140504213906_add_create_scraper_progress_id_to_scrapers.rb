class AddCreateScraperProgressIdToScrapers < ActiveRecord::Migration
  def change
    add_column :scrapers, :create_scraper_progress_id, :integer
  end
end
