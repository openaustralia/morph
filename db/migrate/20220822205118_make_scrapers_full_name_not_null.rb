class MakeScrapersFullNameNotNull < ActiveRecord::Migration[4.2][5.2]
  def change
    change_column_null :scrapers, :full_name, false
  end
end
