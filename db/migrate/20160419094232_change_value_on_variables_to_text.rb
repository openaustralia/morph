class ChangeValueOnVariablesToText < ActiveRecord::Migration[4.2]
  def change
    change_column :variables, :value, :text
  end
end
