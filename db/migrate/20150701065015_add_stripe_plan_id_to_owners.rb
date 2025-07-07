class AddStripePlanIdToOwners < ActiveRecord::Migration[4.2]
  def change
    add_column :owners, :stripe_plan_id, :string
  end
end
