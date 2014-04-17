class AddAdminToOwners < ActiveRecord::Migration
  def change
    add_column :owners, :admin, :boolean, null: false, default: false
  end
end
