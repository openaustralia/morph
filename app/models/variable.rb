class Variable < ActiveRecord::Base
  validates :name, format: {with: /\AMORPH_[A-Z_]+\z/, message: "should look something like MORPH_SEAGULL"}
end
