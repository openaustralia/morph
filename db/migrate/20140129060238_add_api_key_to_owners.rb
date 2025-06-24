class AddApiKeyToOwners < ActiveRecord::Migration[4.2]
  def change
    add_column :owners, :api_key, :string
    Owner.reset_column_information
    reversible do |dir|
      dir.up do
        Owner.all.each do |owner|
          owner.set_api_key
          owner.save!
        end
      end
    end
  end
end
