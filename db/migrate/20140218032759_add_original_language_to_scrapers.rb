class AddOriginalLanguageToScrapers < ActiveRecord::Migration
  def change
    add_column :scrapers, :original_language, :string
  end
end
