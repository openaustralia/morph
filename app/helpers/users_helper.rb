# typed: false
# frozen_string_literal: true

module UsersHelper
  def alert_scrapers_summary_sentence(success_count, broken_count)
    result = []
    result << pluralize(success_count, "scraper")
    result << " you are watching "
    result << (success_count == 1 ? "has" : "have")
    result << " run successfully in the last 48 hours. "
    result << (broken_count == 1 ? "This" : "These")
    result << " "
    result << broken_count.to_s
    result << " "
    result << (broken_count == 1 ? "has" : "have")
    result << " a problem:"
    safe_join(result)
  end
end
