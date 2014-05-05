class RemoveOldProgressFromScrapers < ActiveRecord::Migration
  def change
    remove_column :scrapers, :forking, :boolean
    remove_column :scrapers, :forking_message, :string
    remove_column :scrapers, :forking_progress, :integer
  end
end
