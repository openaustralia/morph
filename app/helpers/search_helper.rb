# typed: true
# frozen_string_literal: true

module SearchHelper
  # For sorbet
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Helpers::TagHelper

  def no_search_results_message(things, search_term)
    safe_join(["Sorry, we couldn't find any ", things, " relevant to your search term ", content_tag(:strong, "“#{search_term}”"), "."])
  end
end
