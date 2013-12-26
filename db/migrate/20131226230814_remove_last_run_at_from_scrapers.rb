class RemoveLastRunAtFromScrapers < ActiveRecord::Migration
  def change
    remove_column :scrapers, :last_run_at, :string
  end
end
