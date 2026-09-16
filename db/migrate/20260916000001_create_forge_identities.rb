# frozen_string_literal: true

# An Owner's account on a Forge (GitHub or GitLab) moves off the owners table
# into its own row, so one Owner can hold an identity on each forge (ADR 0008).
class CreateForgeIdentities < ActiveRecord::Migration[6.1]
  def up
    create_table :forge_identities do |t|
      t.references :owner, foreign_key: true, type: :integer, null: false
      t.string :forge_key, null: false
      t.string :uid, null: false
      t.string :login, null: false
      t.string :access_token
      t.string :refresh_token
      t.datetime :token_expires_at
      t.string :scopes

      t.index %i[forge_key uid], unique: true
      t.index %i[owner_id forge_key], unique: true

      t.timestamps
    end

    # Every existing owner with a uid is a GitHub account; the provider column
    # was only ever written as "github" (and left nil on Organizations).
    execute <<~SQL.squish
      INSERT INTO forge_identities (owner_id, forge_key, uid, login, access_token, created_at, updated_at)
      SELECT id, 'github', uid, nickname, access_token, NOW(), NOW()
      FROM owners
      WHERE uid IS NOT NULL AND uid <> '' AND nickname IS NOT NULL
    SQL

    remove_column :owners, :provider
    remove_column :owners, :uid
    remove_column :owners, :access_token
  end

  def down
    add_column :owners, :provider, :string
    add_column :owners, :uid, :string
    add_column :owners, :access_token, :string

    execute <<~SQL.squish
      UPDATE owners
      INNER JOIN forge_identities ON forge_identities.owner_id = owners.id AND forge_identities.forge_key = 'github'
      SET owners.provider = CASE WHEN owners.type = 'User' THEN 'github' END,
          owners.uid = forge_identities.uid,
          owners.access_token = forge_identities.access_token
    SQL

    drop_table :forge_identities
  end
end
