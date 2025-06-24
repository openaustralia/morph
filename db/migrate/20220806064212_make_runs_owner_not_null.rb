class MakeRunsOwnerNotNull < ActiveRecord::Migration[4.2][5.2]
  def change
    change_column_null :runs, :owner_id, false
  end
end
