class AddDomainIdIndexToConnectionLogs < ActiveRecord::Migration
  def change
    add_index :connection_logs, :domain_id
  end
end
