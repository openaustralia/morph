class AlertMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::AssetUrlHelper
  default from: "morph.io <contact@morph.io>"

  def alert_email(user, broken_scrapers, successful_count)
    broken_runs = broken_scrapers.map {|s| s.last_run}
    count = broken_runs.count
    @user, @successful_count = user, successful_count
    @analytics_params = {utm_medium: "email", utm_source: "alerts"}
    # The ones that are broken for the longest time come last
    @broken_runs = broken_runs.sort do |a,b|
      if b.scraper.latest_successful_run_time.nil? && a.scraper.latest_successful_run_time.nil?
        0
      elsif b.scraper.latest_successful_run_time.nil?
        -1
      elsif a.scraper.latest_successful_run_time.nil?
        1
      else
        b.scraper.latest_successful_run_time <=> a.scraper.latest_successful_run_time
      end
    end
    @subject = "morph.io: #{pluralize(count, 'scraper')} you are watching #{count == 1 ? "is" : "are"} erroring"

    attachments.inline['logo_75x75.png'] = File.read(File.join(Rails.root, "app", "assets", path_to_image("logo_75x75.png")))
    mail(to: "#{user.name} <#{user.email}>", subject: @subject) if user.email
  end
end
