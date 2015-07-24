class AddAlertedAtToOwners < ActiveRecord::Migration
  def change
    add_column :owners, :alerted_at, :datetime
  end
end
