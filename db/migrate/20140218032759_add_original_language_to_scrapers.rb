class AddOriginalLanguageToScrapers < ActiveRecord::Migration[4.2]
  def change
    add_column :scrapers, :original_language, :string
  end
end
