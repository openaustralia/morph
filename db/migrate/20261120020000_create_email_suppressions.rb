# frozen_string_literal: true

class CreateEmailSuppressions < ActiveRecord::Migration[6.1]
  def change
    create_table :email_suppressions do |t|
      t.string :address, null: false
      t.string :reason, null: false
      t.string :postal_event
      t.string :reply_excerpt
      t.datetime :suppressed_at, null: false
      t.datetime :lifted_at
      t.timestamps

      # One row per address. A repeat hard bounce after a lift reuses the row.
      t.index :address, unique: true
    end
  end
end
