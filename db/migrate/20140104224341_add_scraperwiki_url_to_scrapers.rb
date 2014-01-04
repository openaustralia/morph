class AddScraperwikiUrlToScrapers < ActiveRecord::Migration
  def change
    add_column :scrapers, :scraperwiki_url, :string
  end
end
