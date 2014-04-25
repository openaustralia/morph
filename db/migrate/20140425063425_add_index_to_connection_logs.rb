class AddIndexToConnectionLogs < ActiveRecord::Migration
  def change
    add_index :connection_logs, :run_id
    add_index :connection_logs, :host
  end
end
