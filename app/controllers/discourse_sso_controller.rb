# typed: strict
# frozen_string_literal: true

class DiscourseSsoController < ApplicationController
  extend T::Sig

  before_action :authenticate_user!

  sig { void }
  def sso
    # Will be set because we've just authenticated
    user = T.must(current_user)
    secret = ENV.fetch("DISCOURSE_SECRET", nil)
    sso = Discourse::SingleSignOn.parse(request.query_string, secret)
    sso.email = user.email
    sso.name = user.name
    sso.username = user.nickname
    sso.external_id = user.id # unique to your application
    sso.sso_secret = T.must(secret)

    # Sending the user to Discourse (help.morph.io) is the whole point of
    # this endpoint, so this cross-host redirect is intended.
    redirect_to sso.to_url("#{ENV.fetch('DISCOURSE_URL', nil)}/session/sso_login"), allow_other_host: true
  end
end
