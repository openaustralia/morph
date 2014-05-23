module ScrapersHelper
  def radio_description(repo)
    scraper = Scraper.where(full_name: repo.full_name).first
    if scraper
      a = content_tag(:strong, repo.name)
      a += " &mdash; #{repo.description}".html_safe unless repo.description.blank?
      content_tag(:p, a, class: "text-muted")
    else
      a = content_tag(:strong, repo.name)
      a += " &mdash; #{repo.description}".html_safe unless repo.description.blank?
      a += " (".html_safe + link_to("on GitHub", repo.rels[:html].href, target: "_blank") + ")".html_safe
      a
    end
  end

  def full_name_with_links(scraper)
    link_to(scraper.owner.to_param, scraper.owner) + " / " + link_to(scraper.name, scraper)
  end
end
