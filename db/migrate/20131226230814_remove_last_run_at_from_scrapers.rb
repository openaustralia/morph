class RemoveLastRunAtFromScrapers < ActiveRecord::Migration[4.2]
  def change
    remove_column :scrapers, :last_run_at, :string
  end
end
