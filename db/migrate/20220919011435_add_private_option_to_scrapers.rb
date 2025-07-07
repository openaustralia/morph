class AddPrivateOptionToScrapers < ActiveRecord::Migration[4.2][5.2]
  def change
    add_column :scrapers, :private, :boolean, null: false, default: false
  end
end
