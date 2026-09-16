# frozen_string_literal: true

# Set when a Run went ahead with the repository cloned but nobody able to
# reach the forge's API, so collaborators could not be refreshed (ADR 0007).
# Cleared the next time they are.
class AddPermissionsStaleSinceToScrapers < ActiveRecord::Migration[6.1]
  def change
    add_column :scrapers, :permissions_stale_since, :datetime
  end
end
