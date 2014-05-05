class AddHeadingToCreateScraperProgresses < ActiveRecord::Migration
  def change
    add_column :create_scraper_progresses, :heading, :string
  end
end
