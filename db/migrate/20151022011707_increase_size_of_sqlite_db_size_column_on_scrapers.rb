class IncreaseSizeOfSqliteDbSizeColumnOnScrapers < ActiveRecord::Migration[4.2]
  def change
    change_column :scrapers, :sqlite_db_size, :integer, limit: 8
  end
end
