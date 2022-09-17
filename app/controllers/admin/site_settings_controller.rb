# typed: strict
# frozen_string_literal: true

module Admin
  class SiteSettingsController < ApplicationController
    extend T::Sig

    # TODO: Do we really need to authorise actions here? It seems like overkill. We already know the user is an admin
    sig { void }
    def toggle_read_only_mode
      authorize! :toggle_read_only_mode, SiteSetting
      SiteSetting.toggle_read_only_mode!
      flash[:notice] = "Read-only mode is now #{SiteSetting.read_only_mode ? 'on' : 'off'}"
      redirect_to admin_dashboard_url
    end

    sig { void }
    def update_maximum_concurrent_scrapers
      params_maximum_concurrent_scrapers = T.cast(params[:maximum_concurrent_scrapers], T.any(String, Numeric))

      authorize! :update_maximum_concurrent_scrapers, SiteSetting
      SiteSetting.maximum_concurrent_scrapers = params_maximum_concurrent_scrapers.to_i
      flash[:notice] = "Updated maximum concurrent scrapers to #{SiteSetting.maximum_concurrent_scrapers}"
      redirect_to admin_dashboard_url
    end

    private

    # Overriding the default ability class name used because we've split them out. See
    # https://github.com/CanCanCommunity/cancancan/blob/develop/docs/split_ability.md
    sig { returns(SiteSettingAbility) }
    def current_ability
      @current_ability ||= T.let(SiteSettingAbility.new(current_user), T.nilable(SiteSettingAbility))
    end
  end
end
