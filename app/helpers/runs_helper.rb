# typed: strict
# frozen_string_literal: true

module RunsHelper
  extend T::Sig

  # For sorbet
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ERB::Util

  sig { params(run: Run).returns(T.nilable(String)) }
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

  # make an array never longer than 4 by summarising things on the end
  sig { params(array: T::Array[String], summary_text: String).returns(T::Array[String]) }
  def summary_of_array(array, summary_text)
    if array.count > 3
      T.must(array[0..2]) + [pluralize(array.count - 3, summary_text)]
    else
      array
    end
  end

  sig { params(domain: Domain).returns(String) }
  def scraped_domain_link(domain)
    link_to domain.name, "http://#{domain.name}", target: "_blank", rel: "noopener"
  end

  sig { params(scraped_domains: T::Array[Domain], with_links: T::Boolean).returns(String) }
  def scraped_domains_list(scraped_domains, with_links: true)
    d = scraped_domains.map { |domain| (with_links ? scraped_domain_link(domain) : domain.name) }
    # If there are more than 3 in the list then summarise
    to_sentence(summary_of_array(d, "other domain"))
  end

  sig { params(scraped_domains: T::Array[Domain]).returns(String) }
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
