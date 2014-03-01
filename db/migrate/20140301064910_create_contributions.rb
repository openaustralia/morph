class CreateContributions < ActiveRecord::Migration
  def change
    create_table :contributions do |t|
      t.integer :scraper_id
      t.integer :user_id

      t.timestamps
    end
  end
end
