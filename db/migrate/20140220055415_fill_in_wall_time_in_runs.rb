class FillInWallTimeInRuns < ActiveRecord::Migration
  def change
    Run.update_all("wall_time = TO_SECONDS(finished_at) - TO_SECONDS(started_at)",
      "started_at IS NOT NULL AND finished_at IS NOT NULL")
  end
end
