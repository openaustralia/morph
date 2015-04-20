class RemoveHostFromConnectionLogs < ActiveRecord::Migration
  def change
    remove_column :connection_logs, :host, :string
  end
end
