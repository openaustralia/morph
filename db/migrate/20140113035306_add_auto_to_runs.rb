class AddAutoToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :auto, :boolean, null: false, default: false
  end
end
