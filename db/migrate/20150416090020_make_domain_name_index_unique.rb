class MakeDomainNameIndexUnique < ActiveRecord::Migration[4.2]
  def change
    remove_index :domains, :name
    add_index :domains, :name, unique: true
  end
end
