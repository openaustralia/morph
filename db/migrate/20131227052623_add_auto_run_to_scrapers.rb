class AddAutoRunToScrapers < ActiveRecord::Migration[4.2]
  def change
    add_column :scrapers, :auto_run, :boolean, null: false, default: false
  end
end
