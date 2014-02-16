class AlertMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::AssetUrlHelper
  default from: "contact@morph.io"

  def alert_email(user, broken_runs, successful_count)
    count = broken_runs.count
    @user, @successful_count = user, successful_count
    # The ones that are broken for the longest time come first
    @broken_runs = broken_runs.sort{|a,b| a.scraper.latest_successful_run_time <=> b.scraper.latest_successful_run_time}
    @subject = "Morph: #{pluralize(count, 'scraper')} you are watching #{count == 1 ? "is" : "are"} erroring"

    attachments.inline['logo_75x75.png'] = File.read(File.join(Rails.root, "app", "assets", path_to_image("logo_75x75.png")))
    mail(to: "#{user.name} <#{user.email}>", subject: @subject)
  end
end
