module RunsHelper
  def database_changes_in_words(run)
    sections = []
    if run.records_added && run.records_added > 0
      sections << pluralize(run.records_added, "record") + " added"
    end
    if run.records_removed && run.records_removed > 0
      sections << pluralize(run.records_removed, "record") + " removed"
    end
    if run.records_changed && run.records_changed > 0
      sections << pluralize(run.records_changed, "record") + " updated"
    end
    if run.records_added && run.records_removed && run.records_changed &&
      run.records_added == 0 && run.records_removed == 0 && run.records_changed == 0
        sections << "nothing changed"
    end
    unless sections.empty?
      sections.join(", ") + " in the database"
    end
  end

  # make an array never longer than 4 by summaring things on the end
  def summary_of_array(array, summary_text)
    if array.count > 3
      array[0..2] + [pluralize(array.count - 3, summary_text)]
    else
      array
    end
  end

  def scraped_domain_link(domain)
    link_to h(domain.name), h("http://#{domain.name}"), target: "_blank"
  end

  def scraped_domains_list(scraped_domains, with_links = true)
    d = scraped_domains.map{|d| (with_links ? scraped_domain_link(d) : h(d.name))}
    # If there are more than 3 in the list then summarise
    summary_of_array(d, "other domain".html_safe).to_sentence.html_safe
  end

  def simplified_scraped_domains_list(scraped_domains)
    d = scraped_domains.map{|d| h(d.name)}
    # If there are more than 3 in the list then summarise
    if d.count > 3
      summary_of_array(d, "other").to_sentence
    else
      d.join(", ")
    end
  end
end
