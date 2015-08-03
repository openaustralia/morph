class AlertMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::AssetUrlHelper
  add_template_helper UsersHelper
  default from: "morph.io <contact@morph.io>"

  def alert_email(user, broken_scrapers, successful_scrapers)
    @user, @broken_scrapers, @successful_scrapers = user, broken_scrapers, successful_scrapers
    @analytics_params = {utm_medium: "email", utm_source: "alerts"}

    @subject = "#{pluralize(broken_scrapers.count, 'scraper')} you are watching #{broken_scrapers.count == 1 ? "has" : "have"} errored in the last 48 hours"

    attachments.inline['logo_75x75.png'] = File.read(File.join(Rails.root, "app", "assets", path_to_image("logo_75x75.png")))
    if user.email
      mail(to: "#{user.name} <#{user.email}>", subject: @subject)
      user.update(alerted_at: Time.current)
    end
  end
end
