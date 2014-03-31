class MakeQueryLongerInApiQueries < ActiveRecord::Migration
  def change
    change_column :api_queries, :query, :text
  end
end
