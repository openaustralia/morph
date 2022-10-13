# typed: strict
# frozen_string_literal: true

# Contribution of a user to the code a scraper
class Collaboration < ApplicationRecord
  belongs_to :owner
  belongs_to :scraper
end
