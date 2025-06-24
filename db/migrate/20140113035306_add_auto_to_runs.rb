class AddAutoToRuns < ActiveRecord::Migration[4.2]
  def change
    add_column :runs, :auto, :boolean, null: false, default: false
  end
end
