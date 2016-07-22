class AddTimestampToLogLines < ActiveRecord::Migration
  def change
    add_column :log_lines, :timestamp, :datetime
  end
end
