class Alert < ActiveRecord::Base
  belongs_to :watch, polymorphic: true
  belongs_to :user
end
