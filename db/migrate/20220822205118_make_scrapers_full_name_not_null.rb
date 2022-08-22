class MakeScrapersFullNameNotNull < ActiveRecord::Migration[5.2]
  def change
    change_column_null :scrapers, :full_name, false
  end
end
