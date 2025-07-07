class AddAlertedAtToOwners < ActiveRecord::Migration[4.2]
  def change
    add_column :owners, :alerted_at, :datetime
  end
end
