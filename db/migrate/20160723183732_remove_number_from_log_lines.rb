class RemoveNumberFromLogLines < ActiveRecord::Migration[4.2]
  def change
    remove_column :log_lines, :number, :integer, limit: 4
  end
end
