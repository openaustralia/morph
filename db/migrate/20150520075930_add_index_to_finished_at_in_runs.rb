class AddIndexToFinishedAtInRuns < ActiveRecord::Migration[4.2]
  def change
    add_index :runs, :finished_at
  end
end
