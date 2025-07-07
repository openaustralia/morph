class MoveRunMetricForeignKey < ActiveRecord::Migration[4.2]
  def change
    add_column :metrics, :run_id, :integer
    reversible do |dir|
      dir.up do
        Metric.connection.execute("UPDATE metrics, runs SET metrics.run_id = runs.id WHERE runs.metric_id = metrics.id")
      end

      dir.down do
        Metric.connection.execute("UPDATE metrics, runs SET runs.metric_id = metrics.id WHERE metrics.run_id = runs.id")
      end
    end
    remove_column :runs, :metric_id, :integer
  end
end
