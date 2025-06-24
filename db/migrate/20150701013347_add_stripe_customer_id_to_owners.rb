class AddStripeCustomerIdToOwners < ActiveRecord::Migration[4.2]
  def change
    add_column :owners, :stripe_customer_id, :string
  end
end
