class AddMetricIdToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :metric_id, :integer
  end
end
