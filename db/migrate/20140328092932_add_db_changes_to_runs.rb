class AddDbChangesToRuns < ActiveRecord::Migration[4.2]
  def change
    add_column :runs, :tables_added, :integer
    add_column :runs, :tables_removed, :integer
    add_column :runs, :tables_changed, :integer
    add_column :runs, :tables_unchanged, :integer
    add_column :runs, :records_added, :integer
    add_column :runs, :records_removed, :integer
    add_column :runs, :records_changed, :integer
    add_column :runs, :records_unchanged, :integer
  end
end
