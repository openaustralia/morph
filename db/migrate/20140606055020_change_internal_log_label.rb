class ChangeInternalLogLabel < ActiveRecord::Migration
  def up
    LogLine.update_all({stream: "internalerr"}, {stream: "internal"})
  end

  def down
    LogLine.update_all({stream: "internal"}, {stream: "internalerr"})
  end
end
