class AddDomainIdIndexToConnectionLogs < ActiveRecord::Migration[4.2]
  def change
    add_index :connection_logs, :domain_id
  end
end
