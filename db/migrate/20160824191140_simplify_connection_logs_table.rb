class SimplifyConnectionLogsTable < ActiveRecord::Migration[4.2]
  def change
    # Removing a bunch of data that we were wanting to collect but weren't
    # actually using. Doing this because this table was growing very large
    # in production >30GB.
    reversible do |dir|
      dir.up do
        change_table :connection_logs do |t|
          t.remove :response_code, :response_size, :request_size, :path,
                   :scheme, :method, :updated_at
        end
      end

      dir.down do
        change_table :connection_logs do |t|
          t.integer :response_code, limit: 4
          t.integer :response_size, limit: 4
          t.integer :request_size,  limit: 4
          t.text :path, limit: 65535
          t.string :scheme, limit: 255
          t.string :method, limit: 255
          t.datetime :updated_at
        end
      end
    end
  end
end
