class PopulateRepoSizeInScrapers < ActiveRecord::Migration[4.2]
  def change
    Scraper.all.each { |s| s.update_repo_size }
  end
end
