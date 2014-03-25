module OwnersHelper
  def owner_image(owner, size, show_tooltip = true)
    options = {size: "#{size}x#{size}", class: ""}
    if owner.user?
      options[:class] += " img-circle"
    end
    if show_tooltip
      options[:class] += " has-tooltip"
      options[:data] = {placement: "bottom", title: owner.nickname}
    end
    image_tag owner.gravatar_url(size), options
  end
end
