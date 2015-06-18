class AddIndexesToRuns < ActiveRecord::Migration
  def change
    add_index :runs, :created_at
    add_index :runs, :docker_image
  end
end
