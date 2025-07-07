class AddForkingMessageToScrapers < ActiveRecord::Migration[4.2]
  def change
    add_column :scrapers, :forking_message, :string
    add_column :scrapers, :forking_progress, :integer
  end
end
