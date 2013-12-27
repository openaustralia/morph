class AddAutoRunToScrapers < ActiveRecord::Migration
  def change
    add_column :scrapers, :auto_run, :boolean, null: false, default: false
  end
end
