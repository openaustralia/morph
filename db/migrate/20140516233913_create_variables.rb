class CreateVariables < ActiveRecord::Migration
  def change
    create_table :variables do |t|
      t.string :name
      t.string :value
      t.integer :scraper_id

      t.timestamps
    end
  end
end
