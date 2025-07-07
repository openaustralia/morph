class AddGitUrlToScrapers < ActiveRecord::Migration[4.2]
  def change
    add_column :scrapers, :git_url, :string
  end
end
