class AddMoreInfoToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :gravatar_id, :string
    add_column :users, :blog, :string
    add_column :users, :company, :string
    add_column :users, :email, :string
  end
end
