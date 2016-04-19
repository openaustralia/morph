class ChangeValueOnVariablesToText < ActiveRecord::Migration
  def change
    change_column :variables, :value, :text
  end
end
