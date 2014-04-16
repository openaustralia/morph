class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :see_profiler_check

  # With this when logging in on an unauthenticated page it will redirect you to your own user page
  # When forced to log in because we were sent to an authenticated page it will redirect back to the
  # page after logging in
  def user_root_path
    user_path(current_user) if current_user
  end

  # When trying to look at a page on active admin you're not allowed to
  def access_denied(exception)
    redirect_to current_user, :alert => exception.message
  end

  protected

  def see_profiler_check
     # required only in production
     if current_user && current_user.admin?
        Rack::MiniProfiler.authorize_request
     end
  end
end
