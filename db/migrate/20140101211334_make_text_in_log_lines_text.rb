class MakeTextInLogLinesText < ActiveRecord::Migration[4.2]
  def up
    change_column :log_lines, :text, :text
  end

  def down
    change_column :log_lines, :text, :string
  end
end
