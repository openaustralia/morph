class AddStatusCodeToRuns < ActiveRecord::Migration[4.2]
  def change
    add_column :runs, :status_code, :integer
  end
end
