# typed: false
# frozen_string_literal: true

class DiscourseSsoController < ApplicationController
  before_action :authenticate_user!

  def sso
    secret = ENV.fetch("DISCOURSE_SECRET", nil)
    sso = Discourse::SingleSignOn.parse(request.query_string, secret)
    sso.email = current_user.email
    sso.name = current_user.name
    sso.username = current_user.nickname
    sso.external_id = current_user.id # unique to your application
    sso.sso_secret = secret

    redirect_to sso.to_url("#{ENV.fetch('DISCOURSE_URL', nil)}/session/sso_login")
  end
end
