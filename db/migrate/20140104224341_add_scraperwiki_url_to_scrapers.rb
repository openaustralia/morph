class AddScraperwikiUrlToScrapers < ActiveRecord::Migration[4.2]
  def change
    add_column :scrapers, :scraperwiki_url, :string
  end
end
