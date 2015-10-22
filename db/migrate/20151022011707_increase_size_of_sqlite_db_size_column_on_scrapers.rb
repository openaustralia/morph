class IncreaseSizeOfSqliteDbSizeColumnOnScrapers < ActiveRecord::Migration
  def change
    change_column :scrapers, :sqlite_db_size, :integer, limit: 8
  end
end
