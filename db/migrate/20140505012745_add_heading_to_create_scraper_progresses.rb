class AddHeadingToCreateScraperProgresses < ActiveRecord::Migration[4.2]
  def change
    add_column :create_scraper_progresses, :heading, :string
  end
end
