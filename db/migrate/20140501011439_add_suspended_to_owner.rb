class AddSuspendedToOwner < ActiveRecord::Migration
  def change
    add_column :owners, :suspended, :boolean, null: false, default: false
  end
end
