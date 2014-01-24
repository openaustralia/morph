class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :authorize_miniprofiler

  def authorize_miniprofiler
    # Only show Miniprofiler stats in production to mlandauer
    if current_user && current_user.nickname == "mlandauer"
      Rack::MiniProfiler.authorize_request
    end
  end
end
