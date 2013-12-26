class AddLastRunAtToScrapers < ActiveRecord::Migration
  def change
    add_column :scrapers, :last_run_at, :datetime
  end
end
