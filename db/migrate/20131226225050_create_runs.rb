class CreateRuns < ActiveRecord::Migration[4.2]
  def change
    create_table :runs do |t|
      t.integer :scraper_id
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end
  end
end
