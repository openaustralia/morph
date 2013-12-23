class AddGitUrlToScrapers < ActiveRecord::Migration
  def change
    add_column :scrapers, :git_url, :string
  end
end
