class AddStripePlanIdToOwners < ActiveRecord::Migration
  def change
    add_column :owners, :stripe_plan_id, :string
  end
end
