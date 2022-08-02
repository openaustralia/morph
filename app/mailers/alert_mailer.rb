# frozen_string_literal: true

class AlertMailer < ApplicationMailer
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::AssetUrlHelper
  add_template_helper UsersHelper
  default from: "morph.io <contact@morph.io>"

  def alert_email(user, broken_scrapers, successful_scrapers)
    @user = user
    @broken_scrapers = broken_scrapers
    @successful_scrapers = successful_scrapers
    @analytics_params = { utm_medium: "email", utm_source: "alerts" }

    @subject = "#{pluralize(broken_scrapers.count, 'scraper')} you are watching #{broken_scrapers.count == 1 ? 'has' : 'have'} errored in the last 48 hours"

    attachments.inline["logo_75x75.png"] = File.read(File.join(Rails.root, "app", "assets", path_to_image("logo_75x75.png")))
    return if user.email.nil?

    mail(to: "#{user.name} <#{user.email}>", subject: @subject)
    user.update(alerted_at: Time.current)
  end
end
