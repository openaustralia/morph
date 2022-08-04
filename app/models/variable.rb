# typed: false
# frozen_string_literal: true

# A secret environment variable and its value that can be passed to a scraper
class Variable < ApplicationRecord
  belongs_to :scraper
  validates :name, format: {
    with: /\AMORPH_[A-Z0-9_]+\z/,
    message: "should look something like MORPH_SEAGULL"
  }
  validates :value, presence: true

  # Given an array of Variable objects returns a hash of names and values
  def self.to_hash(variables)
    variables.to_h { |v| [v.name, v.value] }
  end
end
