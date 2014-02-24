class PopulateRepoSizeInScrapers < ActiveRecord::Migration
  def change
    Scraper.all.each { |s| s.update_repo_size }
  end
end
