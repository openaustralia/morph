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

  # OmniAuth 2 only starts the OAuth flow on a POST (CVE-2015-9284), so a
  # sign-in control has to be a form rather than a link. The form is
  # `display: inline` so it can sit where the link used to.
  sig { params(forge: Morph::Forge::Base, text: T.nilable(String), html_options: T::Hash[Symbol, T.untyped]).returns(String) }
  def sign_in_with_forge_button(forge, text = nil, html_options = {})
    path = public_send("user_#{forge.key}_omniauth_authorize_path")
    button_to(text || "Sign in with #{forge.name}", path, html_options.merge(form_class: "button_to sign-in"))
  end

  sig { params(text: String, html_options: T::Hash[Symbol, T.untyped]).returns(String) }
  def sign_in_with_github_button(text = "Sign in with GitHub", html_options = {})
    sign_in_with_forge_button(Morph::Forge.for("github"), text, html_options)
  end

  # One button per forge this deployment can sign people in with.
  sig { params(html_options: T::Hash[Symbol, T.untyped]).returns(String) }
  def sign_in_buttons(html_options = {})
    safe_join(Morph::Forge.available.map { |forge| sign_in_with_forge_button(forge, nil, html_options.dup) }, " ")
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
end
