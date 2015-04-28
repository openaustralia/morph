class AlertMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::AssetUrlHelper
  default from: "morph.io <contact@morph.io>"

  def alert_email(user)
    @user, @broken_runs, @successful_count = user, user.broken_runs, user.successful_runs.count
    @analytics_params = {utm_medium: "email", utm_source: "alerts"}
    @subject = "morph.io: #{pluralize(@broken_runs.count, 'scraper')} you are watching #{@broken_runs.count == 1 ? "is" : "are"} erroring"

    attachments.inline['logo_75x75.png'] = File.read(File.join(Rails.root, "app", "assets", path_to_image("logo_75x75.png")))
    mail(to: "#{user.name} <#{user.email}>", subject: @subject) if user.email
  end
end
