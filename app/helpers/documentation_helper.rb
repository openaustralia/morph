# typed: strict
# frozen_string_literal: true

module DocumentationHelper
  extend T::Sig

  # For sorbet
  include ActionView::Helpers::UrlHelper

  sig { params(text: String, file: String).returns(String) }
  def improve_button(text, file)
    link_to text, "https://github.com/openaustralia/morph/blob/master/app/views/documentation/#{file}", class: "btn btn-default improve pull-right"
  end
end
