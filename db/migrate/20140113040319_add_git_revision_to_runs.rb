class AddGitRevisionToRuns < ActiveRecord::Migration[4.2]
  def change
    add_column :runs, :git_revision, :string
  end
end
