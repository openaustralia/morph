class AddForkingToScrapers < ActiveRecord::Migration
  def change
    add_column :scrapers, :forking, :boolean, default: false, null: false
  end
end
