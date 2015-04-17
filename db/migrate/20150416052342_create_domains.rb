class CreateDomains < ActiveRecord::Migration
  def change
    create_table :domains do |t|
      t.string :name, null: false
      t.text :meta

      t.timestamps
    end

    add_index :domains, :name
  end
end
