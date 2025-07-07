class AddIndexUniqueness < ActiveRecord::Migration[4.2][5.2]
  def change
    add_index :scrapers, [:owner_id, :name], unique: true
    remove_index :scrapers, :full_name
    add_index :scrapers, :full_name, unique: true
    add_index :webhooks, [:scraper_id, :url], unique: true
  end
end
