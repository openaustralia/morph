# frozen_string_literal: true

# A Scraper's repository lives on exactly one Forge, and the columns that
# identify it there should not be named after one of them.
class NameScraperForge < ActiveRecord::Migration[6.1]
  def change
    add_column :scrapers, :forge_key, :string, null: false, default: "github"
    rename_column :scrapers, :github_id, :forge_repo_id
    rename_column :scrapers, :github_url, :repo_url
  end
end
