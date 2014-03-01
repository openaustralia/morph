class RemoveGravatarIdFromOwners < ActiveRecord::Migration
  def change
    remove_column :owners, :gravatar_id, :string
  end
end
