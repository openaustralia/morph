class AddLocationToOwners < ActiveRecord::Migration
  def change
    add_column :owners, :location, :string
  end
end
