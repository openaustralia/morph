class AlertMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  default from: "contact@morph.io"

  def alert_email(user, broken_scrapers)
    count = broken_scrapers.count
    mail(
      to: "#{user.name} <#{user.email}>",
      subject: "Morph: #{pluralize(count, 'scraper')} you are watching #{count == 1 ? "is" : "are"} erroring"
      )
  end
end
