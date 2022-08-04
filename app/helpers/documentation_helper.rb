# typed: true
# frozen_string_literal: true

module DocumentationHelper
  # For sorbet
  include ActionView::Helpers::UrlHelper

  def improve_button(text, file, options = {})
    spacer = if options.key?(:spacer)
               options[:spacer]
             else
               true
             end
    c = if spacer
          "btn btn-default improve pull-right"
        else
          "btn btn-default pull-right"
        end
    link_to text, "https://github.com/openaustralia/morph/blob/master/app/views/documentation/#{file}", class: c
  end
end
