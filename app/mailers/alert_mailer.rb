class AlertMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::AssetUrlHelper
  default from: "morph.io <contact@morph.io>"

  def alert_email(user, broken_scrapers, successful_count)
    @user, @broken_scrapers, @successful_count = user, broken_scrapers, successful_count
    @analytics_params = {utm_medium: "email", utm_source: "alerts"}

    @subject = "morph.io: #{pluralize(broken_scrapers.count, 'scraper')} you are watching #{broken_scrapers.count == 1 ? "is" : "are"} erroring"

    attachments.inline['logo_75x75.png'] = File.read(File.join(Rails.root, "app", "assets", path_to_image("logo_75x75.png")))
    mail(to: "#{user.name} <#{user.email}>", subject: @subject) if user.email
  end
end
