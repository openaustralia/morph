# typed: false
# frozen_string_literal: true

class AlertMailerPreview < ActionMailer::Preview
  def alert_email
    user = User.first
    broken_scrapers = Scraper.first(2)
    successful_scrapers = Scraper.last(2)

    AlertMailer.alert_email(user, broken_scrapers, successful_scrapers)
  end
end
