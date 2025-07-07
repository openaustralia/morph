class AddDisableProxyToScrapers < ActiveRecord::Migration[4.2]
  def change
    add_column :scrapers, :disable_proxy, :boolean, null: false, default: false
  end
end
