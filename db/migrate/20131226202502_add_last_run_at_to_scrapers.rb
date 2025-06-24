class AddLastRunAtToScrapers < ActiveRecord::Migration[4.2]
  def change
    add_column :scrapers, :last_run_at, :datetime
  end
end
