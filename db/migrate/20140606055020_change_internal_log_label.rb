class ChangeInternalLogLabel < ActiveRecord::Migration
  def up
    LogLine.where({stream: "internal"}).update_all({stream: "internalerr"})
  end

  def down
    LogLine.where({stream: "internalerr"}).update_all({stream: "internal"})
  end
end
