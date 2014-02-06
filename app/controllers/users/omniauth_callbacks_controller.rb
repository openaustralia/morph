class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    @user = User.find_for_github_oauth(request.env["omniauth.auth"], current_user)

    sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
    flash[:notice] = "Nice person you are. Welcome!"
  end
end