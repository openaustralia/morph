# typed: strict
# frozen_string_literal: true

module ApplicationHelper
  extend T::Sig

  # For sorbet
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::SanitizeHelper
  include Kernel

  sig { params(secs: Float).returns(String) }
  def duration_of_time_in_words(secs)
    distance_of_time_in_words(0, secs, include_seconds: true)
  end

  sig { params(name: T.nilable(String), options: T.untyped, html_options: T::Hash[Symbol, T.untyped], block: T.nilable(T.proc.void)).returns(String) }
  def button_link_to(name = nil, options = {}, html_options = {}, &block)
    if block_given?
      html_options = options
      options = name
      name = capture(&block)
    end
    html_options[:class] ||= ""
    html_options[:class] += " btn btn-default"

    if html_options[:disabled]
      content_tag(:span, name, html_options)
    else
      link_to(name, options, html_options)
    end
  end

  sig { params(text: String, url: String).returns(String) }
  def bs_nav_link(text, url)
    content_tag(:li, link_to(text, url), class: ("active" if current_page?(url)))
  end

  sig { params(key: Symbol, options: T::Hash[T.untyped, T.untyped]).returns(String) }
  def language_name_with_icon(key, options = {})
    l = Morph::Language.new(key)
    safe_join([image_tag(l.image_path, options), " ", l.human])
  end

  # Special method just for sanitizing the result of searchkick highlights and
  # marking it as html safe
  sig { params(text: String).returns(String) }
  def sanitize_highlight(text)
    sanitize(text, tags: ["em"])
  end

  # Returns the appropriate [sub] hostname for the current environment
  sig { params(sub_domain: T.nilable(String)).returns(String) }
  def hostname(sub_domain = nil)
    domain = Morph::Application.default_url_options[:host] || "morph.io"
    if domain.include?("localhost") || sub_domain.blank?
      domain
    else
      "#{sub_domain}.#{domain}"
    end
  end
end
