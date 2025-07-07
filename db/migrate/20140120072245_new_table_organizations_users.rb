class NewTableOrganizationsUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :organizations_users do |table|
      table.integer :organization_id
      table.integer :user_id
    end
  end
end
