class AddIndexToConnectionLogs < ActiveRecord::Migration[4.2]
  def change
    add_index :connection_logs, :run_id
    add_index :connection_logs, :host
  end
end
