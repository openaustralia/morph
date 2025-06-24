class AddFullNameToScrapers < ActiveRecord::Migration[4.2]
  def change
    add_column :scrapers, :full_name, :string
  end
end
