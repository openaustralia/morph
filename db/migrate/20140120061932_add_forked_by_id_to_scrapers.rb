class AddForkedByIdToScrapers < ActiveRecord::Migration[4.2]
  def change
    add_column :scrapers, :forked_by_id, :integer
  end
end
