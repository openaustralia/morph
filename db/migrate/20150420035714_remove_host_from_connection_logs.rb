class RemoveHostFromConnectionLogs < ActiveRecord::Migration[4.2]
  def change
    remove_column :connection_logs, :host, :string
  end
end
