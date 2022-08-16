# typed: true
# frozen_string_literal: true

module DocumentationHelper
  # For sorbet
  include ActionView::Helpers::UrlHelper

  def improve_button(text, file)
    link_to text, "https://github.com/openaustralia/morph/blob/master/app/views/documentation/#{file}", class: "btn btn-default improve pull-right"
  end
end
