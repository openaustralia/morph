class Variable < ActiveRecord::Base
  validates :name, format: {with: /MORPH_[A-Z_]+/, message: "should look something like MORPH_SEAGULL"}
end
