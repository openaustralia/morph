class AddCreatedAtIndexToApiQueries < ActiveRecord::Migration[4.2]
  def change
    add_index :api_queries, :created_at
  end
end
