class AddAdminToOwners < ActiveRecord::Migration[4.2]
  def change
    add_column :owners, :admin, :boolean, null: false, default: false
  end
end
