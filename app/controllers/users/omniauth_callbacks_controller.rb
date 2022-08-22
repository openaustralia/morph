# typed: strict
# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    extend T::Sig

    include Devise::Controllers::Rememberable
    # For sorbet
    include Devise::Controllers::Helpers

    sig { void }
    def github
      new_sign_up = User.find_by(nickname: request.env["omniauth.auth"].info.nickname).blank?

      user = User.find_for_github_oauth(request.env["omniauth.auth"], current_user)
      @user = T.let(user, T.nilable(User))
      # Keep people signed in
      remember_me(user)

      user.watch_all_owners if new_sign_up

      flash[:notice] = render_to_string(partial: "users/sign_in_message")
      sign_in_and_redirect user, event: :authentication # this will throw if @user is not activated
    end
  end
end
