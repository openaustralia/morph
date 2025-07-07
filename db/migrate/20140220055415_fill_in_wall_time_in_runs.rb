class FillInWallTimeInRuns < ActiveRecord::Migration[4.2]
  def change
    Run.where("started_at IS NOT NULL AND finished_at IS NOT NULL").update_all("wall_time = TO_SECONDS(finished_at) - TO_SECONDS(started_at)")
  end
end
