class AddRepoSizeToScrapers < ActiveRecord::Migration[4.2]
  def change
    add_column :scrapers, :repo_size, :integer
  end
end
