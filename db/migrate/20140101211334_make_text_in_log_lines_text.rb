class MakeTextInLogLinesText < ActiveRecord::Migration
  def up
    change_column :log_lines, :text, :text
  end

  def down
    change_column :log_lines, :text, :string
  end
end
