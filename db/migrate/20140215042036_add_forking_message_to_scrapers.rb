class AddForkingMessageToScrapers < ActiveRecord::Migration
  def change
    add_column :scrapers, :forking_message, :string
    add_column :scrapers, :forking_progress, :integer
  end
end
