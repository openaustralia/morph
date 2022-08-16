# typed: strict
# frozen_string_literal: true

module ApplicationHelper
  extend T::Sig

  # For sorbet
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::DateHelper
  include Kernel

  sig { params(secs: Integer).returns(String) }
  def duration_of_time_in_words(secs)
    distance_of_time_in_words(0, secs, include_seconds: true)
  end

  sig { params(name: String, link: String, html_options: T::Hash[Symbol, String]).returns(String) }
  def button_link_to(name, link, html_options = {})
    html_options[:class] ||= ""
    html_options[:class] = "#{T.must(html_options[:class])} btn btn-default"

    if html_options[:disabled]
      content_tag(:span, name, html_options)
    else
      link_to(name, link, html_options)
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
end
