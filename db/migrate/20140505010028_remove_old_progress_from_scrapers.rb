class RemoveOldProgressFromScrapers < ActiveRecord::Migration[4.2]
  def change
    remove_column :scrapers, :forking, :boolean
    remove_column :scrapers, :forking_message, :string
    remove_column :scrapers, :forking_progress, :integer
  end
end
