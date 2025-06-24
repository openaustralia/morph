class AllowNilOnGithubIdInScrapers < ActiveRecord::Migration[4.2]
  def up
    change_column :scrapers, :github_id, :integer, null: true
  end

  def down
    change_column :scrapers, :github_id, :integer, null: false
  end
end
