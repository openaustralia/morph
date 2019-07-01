class AddDisableProxyToScrapers < ActiveRecord::Migration
  def change
    add_column :scrapers, :disable_proxy, :boolean, null: false, default: false
  end
end
