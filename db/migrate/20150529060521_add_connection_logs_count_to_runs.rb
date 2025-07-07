class AddConnectionLogsCountToRuns < ActiveRecord::Migration[4.2]
  def change
    add_column :runs, :connection_logs_count, :integer
  end
end
