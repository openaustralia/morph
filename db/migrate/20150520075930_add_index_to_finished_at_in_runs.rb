class AddIndexToFinishedAtInRuns < ActiveRecord::Migration
  def change
    add_index :runs, :finished_at
  end
end
