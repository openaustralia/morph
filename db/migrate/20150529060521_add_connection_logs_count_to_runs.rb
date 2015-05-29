class AddConnectionLogsCountToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :connection_logs_count, :integer
  end
end
