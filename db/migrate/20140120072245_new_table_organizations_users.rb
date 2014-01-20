class NewTableOrganizationsUsers < ActiveRecord::Migration
  def change
    create_table :organizations_users do |table|
      table.integer :organization_id
      table.integer :user_id
    end
  end
end
