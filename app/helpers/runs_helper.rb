# typed: false
# frozen_string_literal: true

module RunsHelper
  def database_changes_in_words(run)
    sections = []
    sections << "#{pluralize(run.records_added, 'record')} added" if run.records_added&.positive?
    sections << "#{pluralize(run.records_removed, 'record')} removed" if run.records_removed&.positive?
    sections << "#{pluralize(run.records_changed, 'record')} updated" if run.records_changed&.positive?
    sections << "nothing changed" if run.records_added&.zero? && run.records_removed&.zero? && run.records_changed&.zero?
    return if sections.empty?

    changed_text = sections.join(", ")
    "#{changed_text} in the database"
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
    link_to h(domain.name), h("http://#{domain.name}"), target: "_blank", rel: "noopener"
  end

  def scraped_domains_list(scraped_domains, with_links: true)
    d = scraped_domains.map { |domain| (with_links ? scraped_domain_link(domain) : h(domain.name)) }
    # If there are more than 3 in the list then summarise
    summary_of_array(d, "other domain".html_safe).to_sentence.html_safe
  end

  def simplified_scraped_domains_list(scraped_domains)
    d = scraped_domains.map { |domain| h(domain.name) }
    # If there are more than 3 in the list then summarise
    if d.count > 3
      summary_of_array(d, "other").to_sentence
    else
      d.join(", ")
    end
  end
end
