class ConvertPathToTextInConnectionLogs < ActiveRecord::Migration[4.2]
  def change
    change_column :connection_logs, :path, :text
  end
end
