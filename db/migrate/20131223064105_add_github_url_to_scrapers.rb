class AddGithubUrlToScrapers < ActiveRecord::Migration[4.2]
  def change
    add_column :scrapers, :github_url, :string
  end
end
