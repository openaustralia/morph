class MakeDomainNameIndexUnique < ActiveRecord::Migration
  def change
    remove_index :domains, :name
    add_index :domains, :name, unique: true
  end
end
