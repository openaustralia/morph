class CreateSiteSettings < ActiveRecord::Migration[4.2]
  def change
    create_table :site_settings do |t|
      t.string :settings

      t.timestamps
    end
  end
end
