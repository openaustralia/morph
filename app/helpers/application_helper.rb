module ApplicationHelper
  def scraper_path(scraper)
    user_scraper_path(scraper.owner, scraper)
  end
end
