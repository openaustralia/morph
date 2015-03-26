class AddRememberCreatedAtToUsers < ActiveRecord::Migration
  def change
    # Required for devise rememberable
    add_column :owners, :remember_created_at, :datetime
    add_column :owners, :remember_token, :string
  end
end
