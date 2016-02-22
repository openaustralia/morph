class CreateWebhooks < ActiveRecord::Migration
  def change
    create_table :webhooks do |t|
      t.references :scraper, index: true
      t.string :url

      t.timestamps
    end
  end
end
