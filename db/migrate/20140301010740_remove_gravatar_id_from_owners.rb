class RemoveGravatarIdFromOwners < ActiveRecord::Migration[4.2]
  def change
    remove_column :owners, :gravatar_id, :string
  end
end
