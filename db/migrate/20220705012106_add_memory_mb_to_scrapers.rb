class AddMemoryMbToScrapers < ActiveRecord::Migration
  def change
    add_column :scrapers, :memory_mb, :integer
  end
end
