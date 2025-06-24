class ChangeInternalLogLabel < ActiveRecord::Migration[4.2]
  def up
    LogLine.where({stream: "internal"}).update_all({stream: "internalerr"})
  end

  def down
    LogLine.where({stream: "internalerr"}).update_all({stream: "internal"})
  end
end
