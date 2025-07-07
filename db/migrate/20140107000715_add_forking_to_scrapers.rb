class AddForkingToScrapers < ActiveRecord::Migration[4.2]
  def change
    add_column :scrapers, :forking, :boolean, default: false, null: false
  end
end
