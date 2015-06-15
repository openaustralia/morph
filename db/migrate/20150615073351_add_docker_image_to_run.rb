class AddDockerImageToRun < ActiveRecord::Migration
  def change
    add_column :runs, :docker_image, :string
  end
end
