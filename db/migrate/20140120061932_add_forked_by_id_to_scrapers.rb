class AddForkedByIdToScrapers < ActiveRecord::Migration
  def change
    add_column :scrapers, :forked_by_id, :integer
  end
end
