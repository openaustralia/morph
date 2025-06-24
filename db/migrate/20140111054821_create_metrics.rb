class CreateMetrics < ActiveRecord::Migration[4.2]
  def change
    create_table :metrics do |t|
      t.float :wall_time
      t.float :utime
      t.float :stime
      t.integer :maxrss
      t.integer :minflt
      t.integer :majflt
      t.integer :inblock
      t.integer :oublock
      t.integer :nvcsw
      t.integer :nivcsw

      t.timestamps
    end
  end
end
