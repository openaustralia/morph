class AddGravatarUrlToOwners < ActiveRecord::Migration
  def change
    add_column :owners, :gravatar_url, :string
  end
end
