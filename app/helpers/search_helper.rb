module SearchHelper
  def no_search_results_message(things, search_term)
    "Sorry, we couldn't find any ".html_safe + h(things) + " relevant to your search term " + content_tag(:strong, "“" + search_term + "”") + "."
  end
end
