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
      callback_from(Morph::Forge.for("github"))
    end

    sig { void }
    def gitlab
      callback_from(Morph::Forge.for("gitlab"))
    end

    private

    # Signed out, this is a sign-in (or sign-up). Signed in, it links the forge
    # account to the current user (ADR 0008).
    sig { params(forge: Morph::Forge::Base).void }
    def callback_from(forge)
      auth = request.env["omniauth.auth"]
      if user_signed_in?
        link_identity(forge, auth)
      else
        sign_in_with(forge, auth)
      end
    end

    sig { params(forge: Morph::Forge::Base, auth: T.untyped).void }
    def sign_in_with(forge, auth)
      new_sign_up = ForgeIdentity.owner_for(forge.key, auth.uid.to_s).nil?

      user = User.find_or_create_from_oauth(forge, auth)
      @user = T.let(user, T.nilable(User))
      # Keep people signed in
      remember_me(user)

      user.watch_all_owners if new_sign_up

      flash[:notice] = render_to_string(partial: "users/sign_in_message")
      sign_in_and_redirect user, event: :authentication # this will throw if @user is not activated
    end

    sig { params(forge: Morph::Forge::Base, auth: T.untyped).void }
    def link_identity(forge, auth)
      user = T.must(current_user)
      already = ForgeIdentity.owner_for(forge.key, auth.uid.to_s)

      if already && already != user
        flash[:alert] = "That #{forge.name} account is already connected to #{already.nickname} on morph.io. Sign in as them to disconnect it first."
      else
        identity = user.attach_forge_identity!(forge, auth)
        flash[:notice] = "Connected #{forge.name} account #{identity.login}."
      end
      redirect_to settings_owner_path(user)
    end
  end
end
