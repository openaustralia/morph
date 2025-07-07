class AddMetricIdToRuns < ActiveRecord::Migration[4.2]
  def change
    add_column :runs, :metric_id, :integer
  end
end
