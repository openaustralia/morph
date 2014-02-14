module ScrapersHelper
  def radio_description(repo)
    a = content_tag(:strong, repo.full_name)
    a += " &mdash; #{repo.description}".html_safe unless repo.description.blank?
    a += " (".html_safe + link_to("on GitHub", repo.rels[:html].href, target: "_blank") + ")".html_safe
    a
  end
end
