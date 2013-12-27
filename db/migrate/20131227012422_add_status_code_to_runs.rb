class AddStatusCodeToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :status_code, :integer
  end
end
