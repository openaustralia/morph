class AddIndexOnStatusCodeToRuns < ActiveRecord::Migration
  def change
    add_index :runs, [:scraper_id, :status_code, :finished_at]
  end
end
