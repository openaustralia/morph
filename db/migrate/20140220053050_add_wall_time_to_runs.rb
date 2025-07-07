class AddWallTimeToRuns < ActiveRecord::Migration[4.2]
  def change
    add_column :runs, :wall_time, :float, default: 0, null: false
  end
end
