module ScrapersHelper
  def radio_description(repo)
    a = link_to(content_tag(:strong, repo.name), repo.rels[:html].href)
    a += " &mdash; #{repo.description}".html_safe unless repo.description.blank?
    a
  end
end
