class AddSqliteDbSizeToScrapers < ActiveRecord::Migration[4.2]
  def change
    add_column :scrapers, :sqlite_db_size, :integer, null: false, default: 0
    Scraper.reset_column_information
    Scraper.all.each {|s| s.update_sqlite_db_size }
  end
end
