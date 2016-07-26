class RemoveNumberFromLogLines < ActiveRecord::Migration
  def change
    remove_column :log_lines, :number, :integer, limit: 4
  end
end
