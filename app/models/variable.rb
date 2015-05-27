# A secret environment variable and its value that can be passed to a scraper
class Variable < ActiveRecord::Base
  validates :name, format: {
    with: /\AMORPH_[A-Z0-9_]+\z/,
    message: 'should look something like MORPH_SEAGULL'
  }
  validates :value, presence: true
end
