class AddDomainIdToConnectionLogs < ActiveRecord::Migration[4.2]
  class ConnectionLog < ActiveRecord::Base
  end

  def up
    add_column :connection_logs, :domain_id, :integer
    ConnectionLog.find_each do |c|
      domain = Domain.find_by(name: c.host)
      c.update_attribute(:domain_id, domain.id)
    end
  end

  def down
    remove_column :connection_logs, :domain_id, :integer
  end
end
