# typed: strict
# frozen_string_literal: true

module ScrapersHelper
  extend T::Sig

  # For sorbet
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper
  include RunsHelper

  sig { params(name: String, description: T.nilable(String), url: String, exists_on_morph: T::Boolean).returns(String) }
  def radio_description(name:, description:, url:, exists_on_morph:)
    a = []
    a << content_tag(:strong, name)
    if description.present?
      a << " &mdash; ".html_safe
      a << description
    end
    if exists_on_morph
      content_tag(:span, safe_join(a), class: "text-muted")
    else
      link = link_to("on GitHub", url, target: "_blank", rel: "noopener")
      a << " ("
      a << link
      a << ")"
      safe_join(a)
    end
  end

  sig { params(scraper: Scraper).returns(String) }
  def full_name_with_links(scraper)
    safe_join([link_to(scraper.owner.to_param, scraper.owner), " / ", link_to(scraper.name, scraper)])
  end

  # Try to (sort of) handle the situation where text is not properly encoded
  # and so auto_link would normally fail
  sig { params(text: String).returns(String) }
  def auto_link_fallback(text)
    auto_link(text)
  rescue Encoding::CompatibilityError
    text
  end

  sig { params(text: String).returns(T::Boolean) }
  def url?(text)
    u = URI.parse(text)
    %w[http https].include?(u.scheme)
  rescue URI::InvalidURIError
    false
  end

  sig { params(text: String).returns(String) }
  def link_url_or_escape(text)
    url?(text) ? auto_link_fallback(text) : escape_once(text)
  end

  sig { params(scraper: Scraper).returns(String) }
  def scraper_description(scraper)
    description = scraper.description
    if description.present?
      description
    else
      text = "A scraper to collect structured data from "
      text + if scraper.scraped_domains.empty?
               "the web."
             else
               "#{scraped_domains_list(scraper.scraped_domains.to_a, with_links: false)}."
             end
    end
  end

  sig { params(webhook: Webhook).returns(String) }
  def webhook_last_delivery_status(webhook)
    if webhook.last_delivery.blank?
      "unknown"
    elsif webhook.last_delivery.success?
      "success"
    else
      "failure"
    end
  end

  sig { params(number: Integer).returns(Integer) }
  def floor_to_hundreds(number)
    (number / 100.0).floor * 100
  end

  # Give a count of the total number of scrapers rounded down to the nearest
  # hundred so that you can say "more than ... scrapers"
  sig { returns(Integer) }
  def scraper_rounded_count
    floor_to_hundreds(Scraper.count)
  end

  sig { params(private: T::Boolean).returns(String) }
  def privacy_in_words(private)
    private ? "private" : "public"
  end
end
