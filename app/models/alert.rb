# typed: true
# frozen_string_literal: true

# A user watching something - can be a scraper, a user or an org
class Alert < ApplicationRecord
  belongs_to :watch, polymorphic: true
  belongs_to :user
end
