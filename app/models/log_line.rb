class LogLine < ActiveRecord::Base
  belongs_to :run, touch: true
end
