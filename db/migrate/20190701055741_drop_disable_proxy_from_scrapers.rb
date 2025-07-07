class DropDisableProxyFromScrapers < ActiveRecord::Migration[4.2]
  def change
    remove_column :scrapers, :disable_proxy, :boolean, null: false, default: false
  end
end
