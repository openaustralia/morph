class AddFeatureSwitchesToOwners < ActiveRecord::Migration[4.2]
  def change
    add_column :owners, :feature_switches, :string
  end
end
