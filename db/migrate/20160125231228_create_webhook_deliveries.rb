class CreateWebhookDeliveries < ActiveRecord::Migration[4.2]
  def change
    create_table :webhook_deliveries do |t|
      t.references :webhook, index: true
      t.references :run, index: true
      t.datetime :sent_at
      t.integer :response_code

      t.timestamps
    end
  end
end
