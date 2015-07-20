module OwnersHelper
  def owner_image(owner, size, show_tooltip = true, tooltip_text = nil)
    options = {size: "#{size}x#{size}", class: ""}
    if owner.user?
      options[:class] += " img-circle"
    end
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
      options[:data] = {placement: "bottom", title: tooltip_text, html: html, container: 'body'}
    end
    options[:alt] = owner.nickname
    image_tag owner.gravatar_url(size), options
  end

  def owner_tooltip_content(owner)
    if owner.name
      "<h4>#{h(owner.name)}</h4><h5>#{h(owner.nickname)}</h5>"
    else
      "<h4>#{h(owner.nickname)}</h4>"
    end
  end
end
