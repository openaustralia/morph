class AddQueuedAtToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :queued_at, :datetime
  end
end
