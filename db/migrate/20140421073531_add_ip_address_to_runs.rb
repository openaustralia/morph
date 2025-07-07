class AddIpAddressToRuns < ActiveRecord::Migration[4.2]
  def change
    add_column :runs, :ip_address, :string
  end
end
