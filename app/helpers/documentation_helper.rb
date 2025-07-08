# typed: strict
# frozen_string_literal: true

module DocumentationHelper
  extend T::Sig

  # For sorbet
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::SanitizeHelper
  include ERB::Util
  include StaticHelper

  sig { params(text: String, file: String).returns(String) }
  def improve_button(text, file)
    link_to text, "https://github.com/openaustralia/morph/blob/main/app/views/documentation/#{file}", class: "btn btn-default improve pull-right"
  end

  sig { params(text: String, scraper: Scraper, user: T.nilable(User), query: String).returns(String) }
  def substitute_api_params(text, scraper:, user:, query:)
    sanitize(text.sub("[scraper_url]", "#{api_root}<span class='full_name'>#{h(scraper.full_name)}</span>")
                 .sub("[api_key]", "<span class='unescaped-api-key'>#{user ? user.api_key : '[api_key]'}</span>")
                 .sub("[query]", "<span class='unescaped-query'>#{h(query)}</span>"))
  end
end
