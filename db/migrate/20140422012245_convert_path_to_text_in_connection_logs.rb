class ConvertPathToTextInConnectionLogs < ActiveRecord::Migration
  def change
    change_column :connection_logs, :path, :text
  end
end
