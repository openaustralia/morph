class AddIndexToCreatedAtInConnectionLogs < ActiveRecord::Migration[4.2]
  def change
    add_index :connection_logs, :created_at
  end
end
