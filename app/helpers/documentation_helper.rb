module DocumentationHelper
  def improve_button(text, file, options = {})
    if options.has_key?(:spacer)
      spacer = options[:spacer]
    else
      spacer = true
    end
    if spacer
      c = "btn btn-default improve pull-right"
    else
      c = "btn btn-default pull-right"
    end
    link_to text, "https://github.com/openaustralia/morph/blob/master/app/views/documentation/#{file}", class: c
  end
end
