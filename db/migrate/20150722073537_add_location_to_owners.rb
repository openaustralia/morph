class AddLocationToOwners < ActiveRecord::Migration[4.2]
  def change
    add_column :owners, :location, :string
  end
end
