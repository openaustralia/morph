# typed: false
# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  after_action :store_location

  # When trying to look at a page on active admin you're not allowed to
  def access_denied(exception)
    redirect_to current_user, alert: exception.message
  end

  # Handle omniauth failure. See https://github.com/plataformatec/devise/wiki/OmniAuth%3A-Overview#using-omniauth-without-other-authentications
  def new_session_path(_scope)
    new_user_session_path
  end

  private

  def store_location
    # store last url as long as it isn't a /users path
    session[:previous_url] = request.fullpath unless request.fullpath =~ %r{/users}
  end

  def after_sign_in_path_for(resource)
    path = stored_location_for(resource) || session[:previous_url]
    path.nil? || new_user_session_path ? root_path : path
  end

  def after_sign_out_path_for(_resource)
    request.referer ? URI.parse(request.referer).path : root_path
  end
end
