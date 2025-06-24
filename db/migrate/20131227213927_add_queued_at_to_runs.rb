class AddQueuedAtToRuns < ActiveRecord::Migration[4.2]
  def change
    add_column :runs, :queued_at, :datetime
  end
end
