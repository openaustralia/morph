class AddResponseCodeToConnectionLogs < ActiveRecord::Migration[4.2]
  def change
    add_column :connection_logs, :response_code, :integer
  end
end
