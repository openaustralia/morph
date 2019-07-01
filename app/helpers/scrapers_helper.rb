# frozen_string_literal: true

module ScrapersHelper
  def radio_description(repo)
    scraper = Scraper.where(full_name: repo.full_name).first
    a = content_tag(:strong, repo.name)
    a += " &mdash; #{repo.description}".html_safe unless repo.description.blank?
    if scraper
      content_tag(:p, a, class: "text-muted")
    else
      a += " (".html_safe + link_to("on GitHub", repo.rels[:html].href, target: "_blank") + ")".html_safe
      a
    end
  end

  def full_name_with_links(scraper)
    link_to(scraper.owner.to_param, scraper.owner) + " / " + link_to(scraper.name, scraper)
  end

  # Try to (sort of) handle the situation where text is not properly encoded
  # and so auto_link would normally fail
  def auto_link_fallback(text)
    auto_link(text)
  rescue Encoding::CompatibilityError
    text
  end

  def url?(text)
    u = URI.parse(text)
    u.scheme == "http" || u.scheme == "https"
  rescue URI::InvalidURIError
    false
  end

  def link_url_or_escape(text)
    url?(text) ? auto_link_fallback(text) : escape_once(text)
  end

  def scraper_description(scraper)
    if !scraper.description.blank?
      scraper.description
    else
      text = "A scraper to collect structured data from "
      text + if !scraper.scraped_domains.empty?
               "#{scraped_domains_list(scraper.scraped_domains, false)}."
             else
               "the web."
             end
    end
  end

  def webhook_last_delivery_status(webhook)
    if webhook.last_delivery.blank?
      "unknown"
    elsif webhook.last_delivery.success?
      "success"
    else
      "failure"
    end
  end
end
