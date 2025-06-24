class AddMemoryMbToScrapers < ActiveRecord::Migration[4.2]
  def change
    add_column :scrapers, :memory_mb, :integer
  end
end
