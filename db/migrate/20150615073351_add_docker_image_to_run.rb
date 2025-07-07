class AddDockerImageToRun < ActiveRecord::Migration[4.2]
  def change
    add_column :runs, :docker_image, :string
  end
end
