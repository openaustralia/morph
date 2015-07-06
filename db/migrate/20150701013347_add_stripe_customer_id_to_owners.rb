class AddStripeCustomerIdToOwners < ActiveRecord::Migration
  def change
    add_column :owners, :stripe_customer_id, :string
  end
end
