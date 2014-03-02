# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://morph.io"

SitemapGenerator::Sitemap.create do
  Scraper.find_each do |scraper|
    add scraper_path(scraper), lastmod: scraper.updated_at
  end  
  Owner.find_each do |owner|
    add owner_path(owner), lastmod: owner.updated_at
  end
  add documentation_index_path
  add api_documentation_index_path

  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end
end
