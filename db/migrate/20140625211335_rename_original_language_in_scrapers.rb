class RenameOriginalLanguageInScrapers < ActiveRecord::Migration[4.2]
  def change
    rename_column :scrapers, :original_language, :original_language_key
  end
end
