class AddTitleToDomains < ActiveRecord::Migration
  def change
    add_column :domains, :title, :text
  end
end
