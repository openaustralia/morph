# typed: false
# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    include Devise::Controllers::Rememberable

    def github
      new_sign_up = User.find_by(nickname: request.env["omniauth.auth"].info.nickname).blank?

      @user = User.find_for_github_oauth(request.env["omniauth.auth"], current_user)
      # Keep people signed in
      remember_me(@user)

      @user.watch_all_owners if new_sign_up

      flash[:notice] = render_to_string(partial: "users/sign_in_message")
      sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
    end
  end
end
