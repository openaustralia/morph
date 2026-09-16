# frozen_string_literal: true

# Credentials morph.io itself holds for reaching repositories on a forge,
# as opposed to a person's OAuth token which lives on forge_identities.
# A group access token or group deploy token belongs to an Owner (the
# Organization); a project deploy token belongs to one Scraper (ADR 0007).
class CreateForgeCredentials < ActiveRecord::Migration[6.1]
  def change
    create_table :forge_credentials do |t|
      t.references :owner, foreign_key: true, type: :integer
      t.references :scraper, foreign_key: true, type: :integer
      t.string :forge_key, null: false, default: "gitlab"
      t.string :kind, null: false
      t.string :username
      t.string :token, null: false
      t.datetime :expires_at
      t.string :forge_token_id

      t.index %i[owner_id kind]
      t.index %i[scraper_id kind]

      t.timestamps
    end
  end
end
