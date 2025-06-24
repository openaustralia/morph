class AddTitleToDomains < ActiveRecord::Migration[4.2]
  def change
    add_column :domains, :title, :text
  end
end
