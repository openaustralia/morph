class AddResponseCodeToConnectionLogs < ActiveRecord::Migration
  def change
    add_column :connection_logs, :response_code, :integer
  end
end
