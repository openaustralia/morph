class AddCreatedAtIndexToApiQueries < ActiveRecord::Migration
  def change
    add_index :api_queries, :created_at
  end
end
