class CreateConnectionLogs < ActiveRecord::Migration[4.2]
  def change
    create_table :connection_logs do |t|
      t.integer :run_id
      t.string :method
      t.string :scheme
      t.string :host
      t.string :path
      t.integer :request_size
      t.integer :response_size

      t.timestamps
    end
  end
end
