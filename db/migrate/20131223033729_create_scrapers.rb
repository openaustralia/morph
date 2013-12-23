class CreateScrapers < ActiveRecord::Migration
  def change
    create_table :scrapers do |t|
      t.string :name
      t.string :description
      t.integer :owner_id

      t.timestamps
    end
  end
end
