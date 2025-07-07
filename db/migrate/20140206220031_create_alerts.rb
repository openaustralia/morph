class CreateAlerts < ActiveRecord::Migration[4.2]
  def change
    create_table :alerts do |t|
      t.integer :user_id
      t.integer :watch_id
      t.string :watch_type

      t.timestamps
    end
  end
end
