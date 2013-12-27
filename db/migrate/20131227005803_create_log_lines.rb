class CreateLogLines < ActiveRecord::Migration
  def change
    create_table :log_lines do |t|
      t.integer :run_id
      t.string :stream
      t.integer :number
      t.string :text

      t.timestamps
    end
  end
end
