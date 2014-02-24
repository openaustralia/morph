class TweakToRepoSizeInScrapers < ActiveRecord::Migration
  def change
    change_column :scrapers, :repo_size, :integer, null: false, default: 0
  end
end
