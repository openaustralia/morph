class AddFullNameToScrapers < ActiveRecord::Migration
  def change
    add_column :scrapers, :full_name, :string
  end
end
