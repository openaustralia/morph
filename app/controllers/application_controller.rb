# typed: strict
# frozen_string_literal: true

class ApplicationController < ActionController::Base
  extend T::Sig

  # Only redirect back to simple one- or two-segment paths like "/documentation"
  # or "/some_user/some_scraper" after sign out
  SAFE_SIGN_OUT_PATH_REGEXP = T.let(%r{\A(/[^/?#]+){1,2}\z}.freeze, Regexp)

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  after_action :store_location

  # When trying to look at a page on active admin you're not allowed to
  sig { params(exception: StandardError).void }
  def access_denied(exception)
    redirect_to current_user, alert: exception.message
  end

  # Handle omniauth failure. See https://github.com/plataformatec/devise/wiki/OmniAuth%3A-Overview#using-omniauth-without-other-authentications
  sig { params(_scope: T.untyped).returns(String) }
  def new_session_path(_scope)
    new_user_session_path
  end

  private

  sig { void }
  def store_location
    # store last url as long as it isn't a /users path
    session[:previous_url] = request.fullpath unless request.fullpath =~ %r{/users}
  end

  # The referer is client supplied, so only follow it back to a simple path on
  # our own host. Anything else is an open redirect (see issue #1438).
  sig { params(_resource: T.untyped).returns(String) }
  def after_sign_out_path_for(_resource)
    referer = request.referer
    return root_path if referer.blank?

    uri = URI.parse(referer)
    return root_path if uri.host != request.host || uri.query || uri.fragment

    path = uri.path
    return root_path if path.nil? || !path.match?(SAFE_SIGN_OUT_PATH_REGEXP)

    path
  rescue URI::InvalidURIError
    root_path
  end

  # Overriding the default ability class name used because we've split them out. See
  # https://github.com/CanCanCommunity/cancancan/blob/develop/docs/split_ability.md
  # Putting this here we are making it available to the render_sync refetch controller
  # which inherits from this class. I know. It's really ugly. I'm sorry.
  sig { returns(Ability) }
  def current_ability
    @current_ability ||= T.let(ScraperAbility.new(current_user), T.nilable(ScraperAbility))
  end
end
