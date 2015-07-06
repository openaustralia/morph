class AddStripeSubscriptionIdToOwners < ActiveRecord::Migration
  def change
    add_column :owners, :stripe_subscription_id, :string
  end
end
