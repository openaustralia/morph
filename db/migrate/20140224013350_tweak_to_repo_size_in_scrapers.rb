class TweakToRepoSizeInScrapers < ActiveRecord::Migration[4.2]
  def change
    change_column :scrapers, :repo_size, :integer, null: false, default: 0
  end
end
