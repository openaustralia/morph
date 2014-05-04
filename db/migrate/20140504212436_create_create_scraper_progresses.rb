class CreateCreateScraperProgresses < ActiveRecord::Migration
  def change
    create_table :create_scraper_progresses do |t|
      t.string :message
      t.integer :progress

      t.timestamps
    end
  end
end
