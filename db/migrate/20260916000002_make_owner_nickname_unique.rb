# frozen_string_literal: true

# nickname is the one slug behind every owner URL (ADR 0008), so it has to be
# unique. It has always been unique in practice, because it was a GitHub login,
# but the index never said so. Duplicates would mean two Owners answer to one
# URL, which is worth stopping a deploy over rather than papering over.
class MakeOwnerNicknameUnique < ActiveRecord::Migration[6.1]
  def up
    duplicates = select_values(<<~SQL.squish)
      SELECT nickname FROM owners
      WHERE nickname IS NOT NULL
      GROUP BY nickname HAVING COUNT(*) > 1
    SQL
    raise "Owners share a nickname, resolve before migrating: #{duplicates.join(', ')}" if duplicates.any?

    remove_index :owners, :nickname
    add_index :owners, :nickname, unique: true
  end

  def down
    remove_index :owners, :nickname
    add_index :owners, :nickname
  end
end
