class AddGitRevisionToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :git_revision, :string
  end
end
