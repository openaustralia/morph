class SwitchUsersToSti < ActiveRecord::Migration[4.2]
  class User < ActiveRecord::Base
  end

  def change
    add_column :users, :type, :string
    User.reset_column_information
    reversible do |dir|
      dir.up { User.update_all type: "User" }
    end    
    rename_table :users, :owners
  end
end
