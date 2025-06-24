class CreateApiQueries < ActiveRecord::Migration[4.2]
  def change
    create_table :api_queries do |t|
      t.string :type
      t.string :query
      t.integer :scraper_id
      t.integer :owner_id
      t.float :utime
      t.float :stime
      t.float :wall_time
      t.integer :size
      t.string :format

      t.timestamps
    end
  end
end
