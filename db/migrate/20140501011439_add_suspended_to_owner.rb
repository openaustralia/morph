class AddSuspendedToOwner < ActiveRecord::Migration[4.2]
  def change
    add_column :owners, :suspended, :boolean, null: false, default: false
  end
end
