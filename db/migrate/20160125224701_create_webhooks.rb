class CreateWebhooks < ActiveRecord::Migration[4.2]
  def change
    create_table :webhooks do |t|
      t.references :scraper, index: true
      t.string :url

      t.timestamps
    end
  end
end
