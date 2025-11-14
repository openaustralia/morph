# typed: strict
# frozen_string_literal: true

class AlertMailer < ApplicationMailer
  extend T::Sig

  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::AssetUrlHelper
  helper UsersHelper
  default from: "morph.io <contact@morph.io>"

  sig { params(user: User, broken_scrapers: T::Array[Scraper], successful_scrapers: T::Array[Scraper]).void }
  def alert_email(user, broken_scrapers, successful_scrapers)
    @user = T.let(user, T.nilable(User))
    @broken_scrapers = T.let(broken_scrapers, T.nilable(T::Array[Scraper]))
    @successful_scrapers = T.let(successful_scrapers, T.nilable(T::Array[Scraper]))
    @analytics_params = T.let({ utm_medium: "email", utm_source: "alerts" }, T.nilable(T::Hash[Symbol, String]))

    @subject = T.let("#{pluralize(broken_scrapers.count, 'scraper')} you are watching #{broken_scrapers.count == 1 ? 'has' : 'have'} errored in the last 48 hours", T.nilable(String))

    path = Rails.root.join("app/assets").to_s + path_to_image("logo_75x75.png")
    attachments.inline["logo_75x75.png"] = File.read(path)
    return if user.email.nil?

    mail(to: "#{user.name} <#{user.email}>", subject: @subject)
    user.update(alerted_at: Time.current)
  end
end
