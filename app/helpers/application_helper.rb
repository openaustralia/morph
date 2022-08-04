# typed: false
# frozen_string_literal: true

module ApplicationHelper
  def duration_of_time_in_words(secs)
    distance_of_time_in_words(0, secs, include_seconds: true)
  end

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

  def bs_nav_link(text, url)
    content_tag(:li, link_to(text, url), class: ("active" if current_page?(url)))
  end

  def language_name_with_icon(key, options = {})
    l = Morph::Language.new(key)
    safe_join([image_tag(l.image_path, options), " ", l.human])
  end
end
