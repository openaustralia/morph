class DropDisableProxyFromScrapers < ActiveRecord::Migration
  def change
    remove_column :scrapers, :disable_proxy, :boolean, null: false, default: false
  end
end
