# typed: strict
# frozen_string_literal: true

# == Schema Information
#
# Table name: variables
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  value      :text(65535)      not null
#  created_at :datetime
#  updated_at :datetime
#  scraper_id :integer
#
# Indexes
#
#  fk_rails_f537200e37  (scraper_id)
#
# Foreign Keys
#
#  fk_rails_...  (scraper_id => scrapers.id)
#

# A secret environment variable and its value that can be passed to a scraper
# == Schema Information
#
# Table name: variables
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  value      :text(65535)      not null
#  created_at :datetime
#  updated_at :datetime
#  scraper_id :integer
#
# Indexes
#
#  fk_rails_f537200e37  (scraper_id)
#
# Foreign Keys
#
#  fk_rails_...  (scraper_id => scrapers.id)
#
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
