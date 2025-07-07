class AddIndicesOnRelations < ActiveRecord::Migration[4.2]
  def change
    add_index :alerts, :user_id
    # I'm imagining the two below will be better as a compound index but do the dumb and
    # obvious thing first
    add_index :alerts, :watch_id
    add_index :alerts, :watch_type

    add_index :api_queries, :scraper_id
    add_index :api_queries, :owner_id

    add_index :contributions, :scraper_id
    add_index :contributions, :user_id

    add_index :log_lines, :run_id
    add_index :log_lines, :number

    add_index :metrics, :run_id

    add_index :organizations_users, :organization_id
    add_index :organizations_users, :user_id

    add_index :owners, :api_key
    add_index :owners, :nickname

    add_index :runs, :scraper_id
    add_index :runs, :owner_id

    add_index :scrapers, :owner_id
    add_index :scrapers, :full_name
  end
end
