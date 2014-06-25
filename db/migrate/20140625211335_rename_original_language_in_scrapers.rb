class RenameOriginalLanguageInScrapers < ActiveRecord::Migration
  def change
    rename_column :scrapers, :original_language, :original_language_key
  end
end
