class AddGithubUrlToScrapers < ActiveRecord::Migration
  def change
    add_column :scrapers, :github_url, :string
  end
end
