class MakeQueryLongerInApiQueries < ActiveRecord::Migration[4.2]
  def change
    change_column :api_queries, :query, :text
  end
end
