class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Devise::Controllers::Rememberable

  def github
    sign_up = User.find_by(nickname: request.env["omniauth.auth"].info.nickname).blank?

    @user = User.find_for_github_oauth(request.env["omniauth.auth"], current_user)
    # Keep people signed in
    remember_me(@user)

    if sign_up
      @user.watch_all_owners
      flash[:notice] = "Welcome to morph.io! You're now watching any scrapers you have access to."
    else
      flash[:notice] = "Nice person you are. Welcome!"
    end

    sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
  end
end
