class AddCollaboratorsToScrapers < ActiveRecord::Migration[5.2]
  def change
    create_table :collaborations do |t|
      t.references :scraper, foreign_key: true, type: :integer, null: false
      t.references :owner, foreign_key: true, type: :integer, null: false

      t.boolean :admin, null: false
      t.boolean :maintain, null: false
      t.boolean :pull, null: false
      t.boolean :push, null: false
      t.boolean :triage, null: false

      # Adding this index as well because we're likely to be looking up collaborators individually
      # for a particular scraper
      t.index [:scraper_id, :owner_id]

      t.timestamps
    end
  end
end
