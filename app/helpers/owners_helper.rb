# typed: strict
# frozen_string_literal: true

module OwnersHelper
  extend T::Sig

  # For sorbet
  include ERB::Util
  include ActionView::Helpers::AssetTagHelper

  sig { params(owner: Owner, size: Integer, show_tooltip: T::Boolean, tooltip_text: T.nilable(String)).returns(T.nilable(String)) }
  def owner_image(owner, size:, show_tooltip: true, tooltip_text: nil)
    options = { size: "#{size}x#{size}", class: "" }
    options[:class] += " img-circle" if owner.user?
    if show_tooltip
      options[:class] += " has-tooltip"
      # Trying container: 'body' as a workaround for a bug where gravatars move when
      # tooltips are activated
      if tooltip_text.nil?
        tooltip_text = owner_tooltip_content(owner)
        html = true
      else
        html = false
      end
      options[:data] = { placement: "bottom", title: tooltip_text, html: html, container: "body" }
    end
    options[:alt] = owner.nickname
    url = owner.gravatar_url(size)
    image_tag(url, options) if url
  end

  sig { params(owner: Owner).returns(String) }
  def owner_tooltip_content(owner)
    if owner.name
      "<h4>#{h(owner.name)}</h4><h5>#{h(owner.nickname)}</h5>"
    else
      "<h4>#{h(owner.nickname)}</h4>"
    end
  end
end
