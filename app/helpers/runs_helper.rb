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

  def scraped_domains_list(run)
    d = run.scraped_domains
    # If there are more than 3 in the list then summarise
    if d.count > 3
      d = d[0..2] + ["#{d[3..-1].count} other"]
    end
    d.to_sentence
  end
end
