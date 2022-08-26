# typed: strict
# frozen_string_literal: true

# A secret environment variable and its value that can be passed to a scraper
class Variable < ApplicationRecord
  extend T::Sig

  belongs_to :scraper
  validates :name, format: { with: /\AMORPH_[A-Z0-9_]+\z/ }
  validates :value, presence: true

  # Given an array of Variable objects returns a hash of names and values
  sig { params(variables: T::Array[Variable]).returns(T::Hash[String, String]) }
  def self.to_hash(variables)
    variables.to_h { |v| [v.name, v.value] }
  end
end
