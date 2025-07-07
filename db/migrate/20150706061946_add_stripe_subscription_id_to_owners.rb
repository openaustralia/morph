class AddStripeSubscriptionIdToOwners < ActiveRecord::Migration[4.2]
  def change
    add_column :owners, :stripe_subscription_id, :string
  end
end
