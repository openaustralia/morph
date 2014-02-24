class AddRepoSizeToScrapers < ActiveRecord::Migration
  def change
    add_column :scrapers, :repo_size, :integer
  end
end
