class CreateVariables < ActiveRecord::Migration[4.2]
  def change
    create_table :variables do |t|
      t.string :name
      t.string :value
      t.integer :scraper_id

      t.timestamps
    end
  end
end
