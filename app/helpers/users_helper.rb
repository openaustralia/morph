module UsersHelper
  def alert_scrapers_summary_sentence(success_count, broken_count)
    result = pluralize(success_count, "scraper") + " you are watching "
    result += success_count == 1 ? "has" : "have"
    result += " run successfully in the last 48 hours. "
    result += broken_count == 1 ? "This" : "These"
    result += " " + broken_count.to_s + " "
    result += broken_count == 1 ? "has" : "have"
    result += " a problem:"
    result
  end
end
