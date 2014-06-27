module OwnersHelper
  def owner_image(owner, size, show_tooltip = true)
    options = {size: "#{size}x#{size}", class: ""}
    if owner.user?
      options[:class] += " img-circle"
    end
    if show_tooltip
      options[:class] += " has-tooltip"
      # Trying container: 'body' as a workaround for a bug where gravatars move when
      # tooltips are activated
      options[:data] = {placement: "bottom", title: owner.nickname, container: 'body'}
    end
    options[:alt] = owner.nickname
    image_tag owner.gravatar_url(size), options
  end
end
