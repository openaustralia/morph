class AddIpAddressToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :ip_address, :string
  end
end
