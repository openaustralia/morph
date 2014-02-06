class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def after_sign_in_path_for(resource)
    user_path(current_user)
  end

  # Stays on the same page after signing out
  def after_sign_out_path_for(resource_or_scope)
    request.referrer
  end
end
