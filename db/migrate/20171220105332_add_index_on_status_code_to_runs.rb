class AddIndexOnStatusCodeToRuns < ActiveRecord::Migration[4.2]
  def change
    add_index :runs, [:scraper_id, :status_code, :finished_at]
  end
end
