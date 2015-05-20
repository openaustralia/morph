class AddIndexToCreatedAtInConnectionLogs < ActiveRecord::Migration
  def change
    add_index :connection_logs, :created_at
  end
end
