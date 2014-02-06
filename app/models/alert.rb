class Alert < ActiveRecord::Base
  belongs_to :watch, polymorphic: true
end
