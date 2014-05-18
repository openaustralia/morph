module ScrapersHelper
  def radio_description(repo)
    a = content_tag(:strong, repo.name)
    a += " &mdash; #{repo.description}".html_safe unless repo.description.blank?
    a += " (".html_safe + link_to("on GitHub", repo.rels[:html].href, target: "_blank") + ")".html_safe
    a
  end

  def full_name_with_links(scraper)
    link_to(scraper.owner.to_param, scraper.owner) + " / " + link_to(scraper.name, scraper)
  end
end
