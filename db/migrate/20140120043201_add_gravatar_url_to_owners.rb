class AddGravatarUrlToOwners < ActiveRecord::Migration[4.2]
  def change
    add_column :owners, :gravatar_url, :string
  end
end
