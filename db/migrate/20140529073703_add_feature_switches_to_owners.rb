class AddFeatureSwitchesToOwners < ActiveRecord::Migration
  def change
    add_column :owners, :feature_switches, :string
  end
end
